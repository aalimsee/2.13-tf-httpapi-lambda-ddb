


/* A Route 53 hosted zone (e.g., example.com).
An ACM certificate in us-east-1 (required for API Gateway).
A Custom domain for API Gateway (api.example.com).
A Route 53 alias record pointing to the HTTP API.
 */


# Replace with your actual domain
variable "domain_name" {
  default = "sctp-sandbox.com"
}

# Fetch the existing Route 53 hosted zone
data "aws_route53_zone" "selected" {
  name = var.domain_name
}

# Create an ACM certificate for the custom domain (must be in us-east-1)
resource "aws_acm_certificate" "api_cert" {
  domain_name       = "aalimsee-ce9-api.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Create a DNS record for certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : 
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Validate ACM certificate
resource "aws_acm_certificate_validation" "api_cert_validation" {
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation : record.fqdn
  ]
}

# Create an API Gateway custom domain for HTTP API
resource "aws_apigatewayv2_domain_name" "api_domain" {
  domain_name     = "aalimsee-ce9-api.${var.domain_name}"
  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_cert_validation.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2" # 🔹 Required for API Gateway HTTPS
  }
}

/* # Create an HTTP API Gateway
*/

/* # Attach a stage to the HTTP API
*/

# Create a base path mapping for the custom domain
resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = aws_apigatewayv2_api.http_api.id
  domain_name = aws_apigatewayv2_domain_name.api_domain.id
  stage       = aws_apigatewayv2_stage.default.id
}

# Route 53 Alias Record for HTTP API
resource "aws_route53_record" "api_record" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "aalimsee-ce9-api.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

output "DNS" {value = aws_route53_record.api_record.name}
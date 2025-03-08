resource "aws_apigatewayv2_api" "http_api" {
  name          = "${local.name_prefix}-topmovies-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.http_api.id

  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "apigw_lambda" {
  api_id = aws_apigatewayv2_api.http_api.id

  integration_uri        = aws_lambda_function.http_api_lambda.invoke_arn # todo: fill with apporpriate value
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "get_topmovies" {
# todo: fill with apporpriate value
  api_id = aws_apigatewayv2_api.http_api.id
  route_key = "GET /topmovies"
  target = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}" 
}

resource "aws_apigatewayv2_route" "get_topmovies_by_year" {
# todo: fill with apporpriate value
  api_id = aws_apigatewayv2_api.http_api.id
  route_key = "GET /topmovies/{year}"
  target = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}" 

}

resource "aws_apigatewayv2_route" "put_topmovies" {
# todo: fill with apporpriate value
  api_id = aws_apigatewayv2_api.http_api.id
  route_key = "PUT /topmovies"
  target = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}" 
}

resource "aws_apigatewayv2_route" "delete_topmovies_by_year" {
# todo: fill with apporpriate value
  api_id = aws_apigatewayv2_api.http_api.id
  route_key = "DELETE /topmovies/{year}"
  target = "integrations/${aws_apigatewayv2_integration.apigw_lambda.id}" 
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.http_api_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

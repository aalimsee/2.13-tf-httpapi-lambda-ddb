data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/package"
  output_path = "${path.module}/package.zip" # <<<
}

resource "aws_lambda_function" "http_api_lambda" {
  function_name    = "${local.name_prefix}-topmovies-api"
  description      = "Lambda function to write to dynamodb"
  runtime          = "python3.13"
  handler          = "app.lambda_handler"
  
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  
  role             = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.table.name
      SNS_TOPIC_ARN = aws_sns_topic.lambda_email.arn
    } # todo: fill with apporpriate value
  }
}

#---Create SNS for http_api_lambda
resource "aws_sns_topic" "lambda_email" {
  name = "lambda_sns" #var.sns_topic_name
  //tags = var.tags
}

variable "emails" {
  description = "List of email addresses for lambda alerts"
  type        = list(string)
}

resource "aws_sns_topic_subscription" "lambda_email" {
  for_each = toset(var.emails)
  topic_arn = aws_sns_topic.lambda_email.arn
  protocol  = "email"
  endpoint  = each.value
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "http_api_lambda_logs" {
  name_prefix       = "/aws/lambda/${aws_lambda_function.http_api_lambda.function_name}"
  retention_in_days = 7
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.name_prefix}-topmovies-api-executionrole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_exec_role" {
  name = "${local.name_prefix}-topmovies-api-ddbaccess"

# <<<
policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:Scan",
        "dynamodb:DeleteItem"
      ],
      "Resource": "${aws_dynamodb_table.table.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.lambda_email.arn}"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec_role.arn
}



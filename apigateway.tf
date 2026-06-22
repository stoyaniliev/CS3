# HTTP API (cheaper/simpler than REST API) fronting the Lambda.
resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project}-employee-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PATCH", "DELETE", "OPTIONS"]
    allow_headers = ["content-type"]
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.employee_api.invoke_arn
  payload_format_version = "2.0"
}

locals {
  routes = [
    "GET /employees",
    "GET /employees/{id}",
    "POST /employees",
    "PATCH /employees/{id}",
    "DELETE /employees/{id}",
  ]
}

resource "aws_apigatewayv2_route" "r" {
  for_each  = toset(local.routes)
  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.employee_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

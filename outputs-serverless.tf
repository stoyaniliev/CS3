output "employee_api_url" {
  description = "Base URL of the employee API."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "dynamodb_table" {
  description = "DynamoDB table holding employee records."
  value       = aws_dynamodb_table.employees.name
}

# Applies ONLY the Stage 2 private-API resources + the Lambda code update.
# Excludes everything else (especially aws_instance.k3s) so the running cluster is untouched.
$targets = @(
  "aws_vpc_endpoint.execute_api",
  "aws_security_group.api_vpce",
  "aws_api_gateway_rest_api.private",
  "aws_api_gateway_resource.proxy",
  "aws_api_gateway_method.any",
  "aws_api_gateway_integration.lambda",
  "aws_api_gateway_rest_api_policy.private",
  "aws_api_gateway_deployment.private",
  "aws_api_gateway_stage.prod",
  "aws_lambda_permission.apigw_private",
  "aws_lambda_function.employee_api"
)
$args = $targets | ForEach-Object { "-target=$_" }
terraform apply @args

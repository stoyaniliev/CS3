# ============================================================================
# STAGE 2: a PRIVATE REST API for the employee Lambda.
# Stands up ALONGSIDE the existing public HTTP API. Nothing is removed until
# you switch the portal over and verify, so the working system is the fallback.
#
# IMPORTANT: private_dns_enabled = FALSE on the VPC endpoint. With it TRUE, ALL
# execute-api resolution in the VPC is redirected to this endpoint, which would
# break the Stage 1 reverse proxy's calls to the public API. With it FALSE we
# instead call the private API through the endpoint's own DNS name.
# ============================================================================

# --- Interface VPC endpoint for execute-api (private DNS OFF) ---
resource "aws_security_group" "api_vpce" {
  name        = "${var.project}-api-vpce-sg"
  description = "Allow HTTPS to the execute-api VPC endpoint from inside the VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from within the VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "execute_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.vpc.public_subnets
  security_group_ids  = [aws_security_group.api_vpce.id]
  private_dns_enabled = false
}

# --- Private REST API backed by the existing Lambda (greedy {proxy+}) ---
resource "aws_api_gateway_rest_api" "private" {
  name        = "${var.project}-employee-api-private"
  description = "Private REST API for the employee Lambda (VPC-endpoint only)"

  endpoint_configuration {
    types            = ["PRIVATE"]
    vpc_endpoint_ids = [aws_vpc_endpoint.execute_api.id]
  }
}

# Resource policy: allow invoke ONLY through our VPC endpoint
data "aws_iam_policy_document" "private_api_policy" {
  statement {
    effect     = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions    = ["execute-api:Invoke"]
    resources  = ["execute-api:/*"]
  }
  statement {
    effect     = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions    = ["execute-api:Invoke"]
    resources  = ["execute-api:/*"]
    condition {
      test     = "StringNotEquals"
      variable = "aws:SourceVpce"
      values   = [aws_vpc_endpoint.execute_api.id]
    }
  }
}

resource "aws_api_gateway_rest_api_policy" "private" {
  rest_api_id = aws_api_gateway_rest_api.private.id
  policy      = data.aws_iam_policy_document.private_api_policy.json
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.private.id
  parent_id   = aws_api_gateway_rest_api.private.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "any" {
  rest_api_id   = aws_api_gateway_rest_api.private.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.private.id
  resource_id             = aws_api_gateway_resource.proxy.id
  http_method             = aws_api_gateway_method.any.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.employee_api.invoke_arn
}

resource "aws_lambda_permission" "apigw_private" {
  statement_id  = "AllowPrivateRestApiInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.employee_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.private.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "private" {
  rest_api_id = aws_api_gateway_rest_api.private.id
  depends_on  = [aws_api_gateway_integration.lambda]
  triggers = {
    redeploy = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.any.id,
      aws_api_gateway_integration.lambda.id,
    ]))
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.private.id
  deployment_id = aws_api_gateway_deployment.private.id
  stage_name    = "prod"
}

# One private-DNS name of the endpoint (used by the portal nginx as the upstream host).
output "private_api_id" {
  value       = aws_api_gateway_rest_api.private.id
  description = "Private REST API id."
}
output "vpce_dns_name" {
  value       = tolist(aws_vpc_endpoint.execute_api.dns_entry)[0]["dns_name"]
  description = "VPC endpoint regional DNS name to use as the nginx upstream host."
}
output "private_api_invoke_path" {
  value       = "/${aws_api_gateway_stage.prod.stage_name}"
  description = "Stage path prefix (e.g. /prod)."
}

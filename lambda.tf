# IAM role the Lambda runs as.
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.project}-employee-api-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Basic CloudWatch Logs permissions for the function.
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Least-privilege DynamoDB access, scoped to just the employees table (REQ-10).
data "aws_iam_policy_document" "lambda_ddb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
      "dynamodb:DeleteItem", "dynamodb:Scan", "dynamodb:Query"
    ]
    resources = [aws_dynamodb_table.employees.arn]
  }
}

resource "aws_iam_role_policy" "lambda_ddb" {
  name   = "${var.project}-lambda-ddb"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_ddb.json
}

resource "aws_lambda_function" "employee_api" {
  function_name    = "${var.project}-employee-api"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  filename         = "${path.module}/lambda/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda/lambda_function.zip")
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.employees.name
    }
  }
}

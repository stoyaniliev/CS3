# Employee data store (managed, serverless) - replaces the in-cluster Postgres.
resource "aws_dynamodb_table" "employees" {
  name         = "${var.project}-employees"
  billing_mode = "PAY_PER_REQUEST" # no fixed cost; pay per request
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Seed rows so the API has data to show immediately.
resource "aws_dynamodb_table_item" "seed_ada" {
  table_name = aws_dynamodb_table.employees.name
  hash_key   = aws_dynamodb_table.employees.hash_key
  item = jsonencode({
    id         = { S = "1" }, name = { S = "Ada Lovelace" }, email = { S = "ada@innovatech.example" },
    department = { S = "Engineering" }, status = { S = "active" }, role = { S = "Developer" }
  })
}

resource "aws_dynamodb_table_item" "seed_alan" {
  table_name = aws_dynamodb_table.employees.name
  hash_key   = aws_dynamodb_table.employees.hash_key
  item = jsonencode({
    id         = { S = "2" }, name = { S = "Alan Turing" }, email = { S = "alan@innovatech.example" },
    department = { S = "Security" }, status = { S = "active" }, role = { S = "Security Analyst" }
  })
}

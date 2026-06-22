# # Example platform RBAC (REQ-10): a "Developer" persona role.
# data "aws_caller_identity" "current" {}

# data "aws_iam_policy_document" "developer_assume" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "AWS"
#       identifiers = [data.aws_caller_identity.current.account_id]
#     }
#   }
# }

# resource "aws_iam_role" "developer" {
#   name               = "${var.project}-developer"
#   assume_role_policy = data.aws_iam_policy_document.developer_assume.json
# }

# data "aws_iam_policy_document" "developer_permissions" {
#   statement {
#     effect    = "Allow"
#     actions   = ["ec2:DescribeInstances", "ec2:DescribeVolumes"]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_role_policy" "developer" {
#   name   = "${var.project}-developer-policy"
#   role   = aws_iam_role.developer.id
#   policy = data.aws_iam_policy_document.developer_permissions.json
# }

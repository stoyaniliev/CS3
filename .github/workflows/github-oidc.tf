variable "github_repo" {
  description = "GitHub owner/repo allowed to assume the CI role. Empty = disabled."
  type        = string
  default     = ""
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.github_repo == "" ? 0 : 1
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "github_assume" {
  count = var.github_repo == "" ? 0 : 1
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  count              = var.github_repo == "" ? 0 : 1
  name               = "${var.project}-github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_assume[0].json
}

resource "aws_iam_role_policy_attachment" "github_readonly" {
  count      = var.github_repo == "" ? 0 : 1
  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

output "github_actions_role_arn" {
  description = "Set this as the AWS_ROLE_ARN repo variable for the deploy workflow."
  value       = var.github_repo == "" ? "(set github_repo to enable)" : aws_iam_role.github_actions[0].arn
}
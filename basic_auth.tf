# Lambda

data "archive_file" "basic_auth" {
  count = var.enable_basic_auth ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/function/basic_auth.zip"

  source {
    content = templatefile("${path.module}/function/basic_auth.py", {
      SECRET_NAME = aws_secretsmanager_secret.basic_auth.0.name
    })
    filename = "basic_auth.py"
  }
}

resource "aws_lambda_function" "basic_auth" {
  count = var.enable_basic_auth ? 1 : 0

  filename         = "${path.module}/function/basic_auth.zip"
  function_name    = "${replace(var.website_host, ".", "-")}-basic-auth"
  role             = aws_iam_role.basic_auth.0.arn
  handler          = "basic_auth.handler"
  source_code_hash = data.archive_file.basic_auth.0.output_base64sha256
  runtime          = "python3.9"
  description      = "Basic authentication for ${var.website_host}."
  publish          = true

  provider = aws.us-east-1
}

# Secret

resource "random_password" "initial_password" {
  count = var.enable_basic_auth ? 1 : 0

  length  = 20
  special = false
}

resource "aws_secretsmanager_secret" "basic_auth" {
  count = var.enable_basic_auth ? 1 : 0

  name = "basic-auth/${var.website_host}"

  recovery_window_in_days = 0

  provider = aws.us-east-1
}

resource "aws_secretsmanager_secret_version" "basic_auth" {
  count = var.enable_basic_auth ? 1 : 0

  secret_id = aws_secretsmanager_secret.basic_auth.0.id
  secret_string = jsonencode({
    user : var.basic_auth_initial_username
    password : random_password.initial_password.0.result
  })

  provider = aws.us-east-1
}

# IAM

resource "aws_iam_role" "basic_auth" {
  count = var.enable_basic_auth ? 1 : 0

  name = "${var.website_host}-basic-auth"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "basic_auth" {
  count = var.enable_basic_auth ? 1 : 0

  statement {
    sid    = "LogAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    sid    = "SecretAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [aws_secretsmanager_secret.basic_auth.0.arn]
  }
}

resource "aws_iam_role_policy" "basic_auth" {
  count = var.enable_basic_auth ? 1 : 0

  role = aws_iam_role.basic_auth.0.id

  policy = data.aws_iam_policy_document.basic_auth.0.json
}


resource "aws_iam_role" "lambda" {
  for_each = var.functions

  name                  = local.function_names[each.key]
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  version = "2012-10-17"
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
  }
}

# Custom - statements applied to all functions, plus those amended to individual functions
resource "aws_iam_policy" "custom" {
  for_each = var.functions

  name   = "${each.key}-custom"
  policy = data.aws_iam_policy_document.custom[each.key].json
}

data "aws_iam_policy_document" "custom" {
  for_each = var.functions

  version = "2012-10-17"

  # Policy documents must contain at least one statement. If the configuration provides neither
  # general nor function-specific statements, a meaningless no-op is used.
  dynamic "statement" {
    for_each = coalescelist(
      concat(var.iam_statements, each.value.iam_statements),
      [{ sid = "noop", effect = "Allow", actions = ["none:null"], resources = ["*"] }],
    )
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role_policy_attachment" "custom" {
  for_each = var.functions

  role       = aws_iam_role.lambda[each.key].name
  policy_arn = aws_iam_policy.custom[each.key].arn
}

# CloudWatch Logs
# Dynamically generate each function's LogGroup ARN to avoid circular dependencies
locals {
  log_group_arns = {
    for function_name, _ in var.functions :
    function_name => "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.function_names[function_name]}"
  }
}

resource "aws_iam_policy" "logging" {
  for_each = var.functions

  name   = "${each.key}-logs"
  policy = data.aws_iam_policy_document.logging[each.key].json
}

# trivy:ignore:AVD-AWS-0057: Grant broad CloudWatch Logs permission during development
data "aws_iam_policy_document" "logging" {
  for_each = var.functions

  version = "2012-10-17"

  statement {
    effect    = "Allow"
    actions   = ["logs:*"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = [local.log_group_arns[each.key]]
  }

  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${local.log_group_arns[each.key]}:*"]
  }

  # checkov:skip=CKV_AWS_111: Grant broad CloudWatch Logs permission during development
  # checkov:skip=CKV_AWS_356: Grant broad CloudWatch Logs permission during development
}

resource "aws_iam_role_policy_attachment" "logging" {
  for_each = var.functions

  role       = aws_iam_role.lambda[each.key].name
  policy_arn = aws_iam_policy.logging[each.key].arn
}

# VPC
resource "aws_iam_role_policy_attachment" "vpc" {
  for_each = { for k, v in var.functions : k => v if v.vpc_security_group_ids != null && v.vpc_subnet_ids != null }

  role       = aws_iam_role.lambda[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess"
}

# Tracing
resource "aws_iam_role_policy_attachment" "tracing" {
  for_each = { for k, v in var.functions : k => v if v.tracing_config_mode != null || var.tracing_config_mode != null }

  role       = aws_iam_role.lambda[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

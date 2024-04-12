# trivy:ignore:AVD-AWS-0066: Tracing is configured by user
resource "aws_lambda_function" "this" {
  for_each = var.functions

  function_name     = local.function_names[each.key]
  handler           = each.value.handler
  role              = aws_iam_role.lambda[each.key].arn
  runtime           = var.runtime
  s3_bucket         = aws_s3_object.lambda_package.bucket
  s3_key            = aws_s3_object.lambda_package.key
  s3_object_version = aws_s3_object.lambda_package.version_id

  architectures                  = each.value.architectures
  memory_size                    = each.value.memory_size
  publish                        = each.value.publish
  reserved_concurrent_executions = each.value.reserved_concurrent_executions
  timeout                        = each.value.timeout

  code_signing_config_arn = each.value.code_signing_config_arn
  description             = each.value.description
  kms_key_arn             = var.kms_key_arn == null && length(keys(merge(var.environment, each.value.environment))) == 0 ? null : var.kms_key_arn
  layers                  = each.value.layers
  tags                    = var.tags

  dynamic "environment" {
    for_each = length(keys(merge(var.environment, each.value.environment))) == 0 ? [] : [true]
    content {
      variables = merge(var.environment, each.value.environment)
    }
  }

  dynamic "ephemeral_storage" {
    for_each = each.value.ephemeral_storage_size == null ? [] : [each.value.ephemeral_storage_size]
    content {
      size = each.value.ephemeral_storage_size
    }
  }

  dynamic "tracing_config" {
    for_each = (each.value.tracing_config_mode == null && var.tracing_config_mode == null) ? [] : [true]
    content {
      mode = compact([each.value.tracing_config_mode, var.tracing_config_mode])
    }
  }

  dynamic "vpc_config" {
    for_each = (each.value.vpc_security_group_ids == null && each.value.vpc_subnet_ids == null) ? [] : [true]
    content {
      security_group_ids = each.value.vpc_security_group_ids
      subnet_ids         = each.value.vpc_subnet_ids
    }
  }

  # Avoid race conditions with AWS' automatically-created log groups
  depends_on = [aws_cloudwatch_log_group.functions]

  # checkov:skip=CKV_AWS_116: Skip DLQ configuration for development
}

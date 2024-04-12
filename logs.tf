resource "aws_cloudwatch_log_group" "functions" {
  for_each = var.functions

  name              = "/aws/lambda/${local.function_names[each.key]}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = var.kms_key_arn
}

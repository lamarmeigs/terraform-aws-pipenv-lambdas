output "functions" {
  value = {
    for function_name, _ in var.functions :
    function_name => {
      name : aws_lambda_function.this[function_name].function_name
      arn : aws_lambda_function.this[function_name].arn
      invoke_arn : aws_lambda_function.this[function_name].invoke_arn
    }
  }
  description = "Map of function names (as input) to finalized function names and ARNs"
}

output "package" {
  value       = module.package.s3_object
  description = "Map of S3 object data (bucket, key, and version_id) for the deployed package"
}

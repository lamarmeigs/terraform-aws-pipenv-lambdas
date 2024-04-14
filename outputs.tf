output "functions" {
  value = {
    for function_name, _ in var.functions :
    function_name => {
      name : aws_lambda_function.this[function_name].function_name
      arn : aws_lambda_function.this[function_name].arn
      invoke_arn : aws_lambda_function.this[function_name].invoke_arn
      version : aws_lambda_function.this[function_name].version
      role_name : aws_iam_role.lambda[function_name].name
    }
  }
  description = "Map of function names (as input) to finalized function names and ARNs"
}

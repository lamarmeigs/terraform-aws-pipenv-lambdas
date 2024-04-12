output "function_name" {
  description = "Name of the created function"
  value       = module.lambda_functions.functions["ExampleFunction"].name
}

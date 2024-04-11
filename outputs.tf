# For guidance, see:
# https://developer.hashicorp.com/terraform/language/values/outputs

output "greeting" {
  value       = local.greeting
  description = "A standard greeting"
}

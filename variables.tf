# For guidance, see:
# https://developer.hashicorp.com/terraform/language/values/variables

variable "name" {
  type        = string
  default     = "World"
  description = "Name of the user to greet"
}

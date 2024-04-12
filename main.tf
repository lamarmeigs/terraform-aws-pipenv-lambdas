terraform {
  required_version = ">= 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.44.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.2"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Lambda names must be shorter than 140 characters, but must also distinguish between functions
# from multiple service instances. Map their provided names to a concatenation with the
# function_prefix (if provided for brevity) or the full service name.
locals {
  function_names = {
    for function_name, _ in var.functions :
    function_name => (var.function_prefix != null) ? "${var.function_prefix}-${function_name}" : "${var.service}-${function_name}"
  }
}

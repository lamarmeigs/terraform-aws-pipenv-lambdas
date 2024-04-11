terraform {
  required_version = ">= 1.7.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.44.0"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  greeting = "Hello, ${var.name} from ${data.aws_caller_identity.current.account_id}"
}

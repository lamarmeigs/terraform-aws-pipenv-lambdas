terraform {
  required_version = ">= 1.7.5"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

resource "random_string" "suffix" {
  length  = 16
  special = false
  upper   = false
}

module "lambda_functions" {
  source = "../../"

  packages = ["src"]
  runtime  = "python3.10"
  root     = "."
  service  = "example-service-${random_string.suffix.result}"
  functions = {
    ExampleFunction = {
      handler = "src.handlers.handle"
    }
  }
}

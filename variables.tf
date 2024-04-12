variable "environment" {
  type        = map(string)
  default     = {}
  description = "Environment variables to set in all functions"
}

variable "function_prefix" {
  type        = string
  default     = null
  description = "A custom string to prefix to each function name (replacing the service name). Use when the service name and function name surpass 140 characters."
}

variable "functions" {
  type = map(
    object({
      architectures           = optional(list(string), ["x86_64"])
      code_signing_config_arn = optional(string)
      description             = optional(string)
      environment             = optional(map(string), {})
      ephemeral_storage_size  = optional(number)
      handler                 = string
      iam_statements = optional(
        list(
          object({
            actions   = list(string)
            sid       = optional(string)
            effect    = string
            resources = list(string)
          })
        ),
        []
      )
      layers                         = optional(list(string))
      memory_size                    = optional(number, 128)
      publish                        = optional(bool, false)
      reserved_concurrent_executions = optional(number, -1)
      timeout                        = optional(number, 6)
      tracing_config_mode            = optional(string)
      vpc_security_group_ids         = optional(list(string))
      vpc_subnet_ids                 = optional(list(string))
    })
  )
  description = "Map of function names to configuration objects. Each object attribute corresponds to a top-level variable or an argument to the aws_lambda_function resource."
}

variable "iam_statements" {
  type = list(
    object({
      sid       = optional(string)
      effect    = string
      actions   = list(string)
      resources = list(string)
    })
  )
  default     = []
  description = "IAM policy statements applied to each function, defining common permissions. Can be amended in individual functions."
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "KMS key used to encrypt build artifacts, environment variables, and logs"
}

variable "log_retention_in_days" {
  type        = number
  default     = 60
  description = "The number of days to retain all functions' logs in CloudWatch"
}

variable "packages" {
  type        = list(string)
  description = "A list of local packages to include in the deployed Lambda build, relative to the root"
}

variable "pipfile_lock_path" {
  type        = string
  default     = "Pipfile.lock"
  description = "Path to the Pipfile.lock to use during builds, relative to the root"
}

variable "root" {
  type        = string
  default     = "../.."
  description = "Root of the build, from which Pipfile.lock and all local packages may be found"
}

variable "runtime" {
  type        = string
  description = "The Lambda runtime. Must be a Python version. See AWS Lambda API docs for supported runtimes."

  validation {
    condition     = startswith(var.runtime, "python")
    error_message = "Only Python runtimes are supported"
  }
}

variable "service" {
  type        = string
  description = "Name of the service"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Map of tags to assign to each function. In case of collisions, will override the provider's `default_tags`."
}

variable "tracing_config_mode" {
  type        = string
  default     = null
  description = "Whether, and how, to sample all functions' incoming requests with AWS X-Ray. Can be overridden on individual functions. See AWS provider docs for more information."
}

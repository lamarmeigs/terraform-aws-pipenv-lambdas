# terraform-aws-pipenv-lambdas

This Terraform module manages multiple Lambda functions from a a single bundle of Python code,
installing their dependencies via pipenv. Its build process, based on [Anton Babenki's excellent
work](https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest) mimics that
of the [serverless framework](https://www.serverless.com/), trading that system's black box magic
for HCL's declarative syntax.


## Examples

### Basic usage:

```hcl
module "example" {
  source = "."

  packages = ["src"]
  runtime  = "python3.10"
  service  = "example"
  functions = {
    ExampleFunction = {
      handler = "path.to.handler"
    }
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.44.0 |
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.2 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_environment"></a> [environment](#input\_environment) | Environment variables to set in all functions | `map(string)` | `{}` | no |
| <a name="input_function_prefix"></a> [function\_prefix](#input\_function\_prefix) | A custom string to prefix to each function name (replacing the service name). Use when the service name and function name surpass 140 characters. | `string` | `null` | no |
| <a name="input_functions"></a> [functions](#input\_functions) | Map of function names to configuration objects. Each object attribute corresponds to a top-level variable or an argument to the aws\_lambda\_function resource. | <pre>map(<br>    object({<br>      architectures           = optional(list(string), ["x86_64"])<br>      code_signing_config_arn = optional(string)<br>      description             = optional(string)<br>      environment             = optional(map(string), {})<br>      ephemeral_storage_size  = optional(number)<br>      handler                 = string<br>      iam_statements = optional(<br>        list(<br>          object({<br>            actions   = list(string)<br>            sid       = optional(string)<br>            effect    = string<br>            resources = list(string)<br>          })<br>        ),<br>        []<br>      )<br>      layers                         = optional(list(string))<br>      memory_size                    = optional(number, 128)<br>      publish                        = optional(bool, false)<br>      reserved_concurrent_executions = optional(number, -1)<br>      timeout                        = optional(number, 6)<br>      tracing_config_mode            = optional(string)<br>      vpc_security_group_ids         = optional(list(string))<br>      vpc_subnet_ids                 = optional(list(string))<br>    })<br>  )</pre> | n/a | yes |
| <a name="input_iam_statements"></a> [iam\_statements](#input\_iam\_statements) | IAM policy statements applied to each function, defining common permissions. Can be amended in individual functions. | <pre>list(<br>    object({<br>      sid       = optional(string)<br>      effect    = string<br>      actions   = list(string)<br>      resources = list(string)<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key used to encrypt build artifacts, environment variables, and logs | `string` | `null` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | The number of days to retain all functions' logs in CloudWatch | `number` | `60` | no |
| <a name="input_packages"></a> [packages](#input\_packages) | A list of local packages to include in the deployed Lambda build, relative to the root | `list(string)` | n/a | yes |
| <a name="input_pipfile_lock_path"></a> [pipfile\_lock\_path](#input\_pipfile\_lock\_path) | Path to the Pipfile.lock to use during builds, relative to the root | `string` | `"Pipfile.lock"` | no |
| <a name="input_root"></a> [root](#input\_root) | Root of the build, from which Pipfile.lock and all local packages may be found | `string` | `"../.."` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | The Lambda runtime. Must be a Python version. See AWS Lambda API docs for supported runtimes. | `string` | n/a | yes |
| <a name="input_service"></a> [service](#input\_service) | Name of the service | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to assign to each function. In case of collisions, will override the provider's `default_tags`. | `map(string)` | `{}` | no |
| <a name="input_tracing_config_mode"></a> [tracing\_config\_mode](#input\_tracing\_config\_mode) | Whether, and how, to sample all functions' incoming requests with AWS X-Ray. Can be overridden on individual functions. See AWS provider docs for more information. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_functions"></a> [functions](#output\_functions) | Map of function names (as input) to finalized function names and ARNs |
| <a name="output_package"></a> [package](#output\_package) | Map of S3 object data (bucket, key, and version\_id) for the deployed package |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.functions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_policy.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.tracing](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_s3_bucket.builds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.builds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_public_access_block.builds_access_block](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.builds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.builds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [null_resource.requirements](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
<!-- END_TF_DOCS -->


## Contributing

This is intended as a thought excercise more than for actual distribution. If you care to fork it
to make your own modifications, have at it!

### Getting started

The module is intended for use in [Terraform](https://www.terraform.io/) configurations. Be sure
to install an appropriate version of the tool (see `main.tf`), preferably via something like
[`tfenv`](https://github.com/tfutils/tfenv).

On a mac, using [homebrew](https://brew.sh/):

```shell
$ brew install tfenv
$ tfenv install 1.7.5
$ tfenv use 1.7.5
```

The packaging module uses Docker to avoid system conflicts when installing your Lambda
functions' dependencies:

```shell
$ brew install docker
```

### Testing

The `examples` directory contain usable root configurations demonstrating the module's usage. When
making changes, be sure that they remain applicable:

```shell
$ export AWS_PROFILE=my-sso-profile && aws sso login
$ cd examples/simple
$ terraform init
$ terraform apply
```

The created functions may then be invoked through the AWS Console or from the command line:

```shell
$ aws lambda invoke --function-name $(terraform output -raw function_name) /dev/stdout
```

This will create new billable resources in your AWS account, so be sure to destroy them when you're
done!

```shell
$ terraform destroy
```

### Validation

For convenience, this project includes [`pre-commit`](https://pre-commit.com) hooks that perform
validation on each commit, catching more egregious errors and ensuring
[style conventions](https://developer.hashicorp.com/terraform/language/syntax/style). They can
be installed via the following commands:

```shell
$ brew install pre-commit tflint trivy go
$ pre-commit install
```

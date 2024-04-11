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

  name = "Alice"
}
```

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.44.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name of the user to greet | `string` | `"World"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_greeting"></a> [greeting](#output\_greeting) | A standard greeting |

## Resources

| Name | Type |
|------|------|
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

# Changelog

All notable changes to this module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [1.1.1] - 2024-04-14

### Added

- Outputs include function's published version and IAM role.

### Fixed

- File permissions in built zip file.


## [1.1.0] - 2024-04-12

### Added

- Local build scripts for hashing and packaging zip file.
- AWS resources for uploading the packaged zip file to S3.

### Removed

- Internal dependency on [`terraform-aws-lambda`](https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest).


## [1.0.0] - 2024-04-12

### Added

- AWS resource definitions (eg. Lambda functions, CloudWatch logs, IAM permissions).
- Local `null_resource` to convert `Pipenv.lock` to `requirements.txt` for consumption by
  [`terraform-aws-lambda`](https://registry.terraform.io/modules/terraform-aws-modules/lambda/aws/latest).

# trivy:ignore:AVD-AWS-0089: Ignore bucket logging
resource "aws_s3_bucket" "builds" {
  bucket = var.service
}

resource "aws_s3_bucket_lifecycle_configuration" "builds" {
  bucket = aws_s3_bucket.builds.id

  rule {
    id = "archive-builds"
    filter {}
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "builds_access_block" {
  bucket                  = aws_s3_bucket.builds.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "builds" {
  bucket = aws_s3_bucket.builds.id

  rule {
    bucket_key_enabled = (var.kms_key_arn == null) ? false : true
    apply_server_side_encryption_by_default {
      kms_master_key_id = (var.kms_key_arn == null) ? null : var.kms_key_arn
      sse_algorithm     = (var.kms_key_arn == null) ? "AES256" : "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "builds" {
  bucket = aws_s3_bucket.builds.id
  versioning_configuration {
    status = "Enabled"
  }
}

# NB: The terraform-aws-modules/lambda module supports only native pip `requirements.txt` file.
# We must create such a file manually based on the pipenv lockfile.
data "local_file" "pipfile_lock" {
  filename = join("/", [var.root, var.pipfile_lock_path])
}

resource "null_resource" "requirements" {
  triggers = {
    lockfile = data.local_file.pipfile_lock.content
  }

  provisioner "local-exec" {
    command = "pipenv requirements > requirements.txt"
  }
}

module "package" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.2"

  depends_on = [null_resource.requirements]

  create_function          = false
  recreate_missing_package = false
  build_in_docker          = true
  runtime                  = var.runtime

  store_on_s3 = true
  s3_bucket   = aws_s3_bucket.builds.id
  source_path = [
    {
      path = var.root
      # A negated negative-lookahead ensures that any local directories not corresponding to
      # var.packages are ignored, without affecting installed third-party dependencies.
      patterns = ["!^(?!${join("|", var.packages)}).*"]
    },
    {
      pip_requirements = "requirements.txt"
    }
  ]

  # checkov:skip=CKV_TF_1: Use version number rather than commit hash for convenience
}

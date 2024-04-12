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

data "external" "hash" {
  program = ["python", "${path.module}/hash.py"]
  query = {
    packages     = jsonencode(var.packages)
    root         = var.root
    pipfile_lock = var.pipfile_lock_path
  }
}

resource "null_resource" "build" {
  triggers = {
    hash = data.external.hash.result.build_hash
  }

  provisioner "local-exec" {
    command = <<-EOT
      ${path.module}/build.py ${data.external.hash.result.filename} \
        --packages ${join(" ", var.packages)} \
        --pipfile_lock ${var.pipfile_lock_path} \
        --root ${var.root} \
        --runtime ${var.runtime}
    EOT
  }
}

resource "aws_s3_object" "lambda_package" {
  depends_on = [null_resource.build]

  acl           = "private"
  bucket        = aws_s3_bucket.builds.id
  key           = data.external.hash.result.filename
  source        = data.external.hash.result.filename
  storage_class = "ONEZONE_IA"
}

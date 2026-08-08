# -------------------------------------------------- #
# ----------- OpenTofu state backend (S3) ---------- #
# -------------------------------------------------- #

# S3 Bucket: stores the OpenTofu state files
resource "aws_s3_bucket" "otf_state_bucket" {
  bucket = var.otf_state_s3_bucket_name
  object_lock_enabled = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "otf_state_bucket_versioning" {
  bucket = aws_s3_bucket.otf_state_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "otf_state_bucket_encryption" {
  bucket = aws_s3_bucket.otf_state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "otf_state_bucket_public_access_block" {
  bucket = aws_s3_bucket.otf_state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object_lock_configuration" "otf_state_bucket_lock" {
  bucket = aws_s3_bucket.otf_state_bucket.id

  object_lock_enabled = "Enabled"
}
terraform {
  backend "s3" {
    bucket         = var.otf_state_s3_bucket_name
    key            = var.otf_state_s3_file_name
    region         = var.aws_region
    use_lockfile   = true
    encrypt        = true
  }
}
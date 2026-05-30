# Configure the Terraform backend to use AWS S3 for remote state storage.
terraform {
  # This backend block instructs Terraform to store state in S3.
  backend "s3" {}
}

# Configure Terraform core settings and provider requirements.
terraform {
  # Require Terraform version 1.4.0 or newer.
  required_version = ">= 1.4.0"

  required_providers {
    # Declare the AWS provider source and supported version range.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

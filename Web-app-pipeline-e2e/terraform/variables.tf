# Declare Terraform variables used across the AWS infrastructure deployment.

variable "aws_region" {
  # AWS region where all resources will be created.
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

variable "aws_account_id" {
  # Account ID used for names, permissions, and ECR repository references.
  description = "AWS account ID used for resource naming and permissions"
  type        = string
  default     = "234951664603"
}

variable "tf_state_bucket" {
  # S3 bucket name that stores Terraform remote state files.
  description = "S3 bucket name for Terraform remote state"
  type        = string
  default     = "webapp-pipeline-terraform-state"
}

variable "tf_state_lock_table" {
  # DynamoDB table name used to lock the Terraform state during operations.
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
  default     = "webapp-pipeline-terraform-lock"
}

variable "tf_state_key" {
  # Path inside the S3 bucket where the Terraform state object is stored.
  description = "Terraform state object path in S3"
  type        = string
  default     = "global/sprint2/terraform.tfstate"
}

variable "terraform_backend_role_name" {
  # IAM role name used for Terraform remote state backend access.
  description = "Name of the IAM role that can access Terraform backend S3 and DynamoDB resources"
  type        = string
  default     = "TerraformS3DynamoAccessRole"
}

variable "backend_attached_role_name" {
  # Name of an existing IAM role to attach the backend access policy to.
  description = "Existing IAM role name (e.g., instanceRole) to grant S3/DynamoDB backend permissions"
  type        = string
  default     = "instanceRole"
}

variable "cluster_name" {
  # Base name for the EKS cluster and related resources.
  description = "EKS cluster name"
  type        = string
  default     = "webapp-pipeline-sprint2-cluster"
}

variable "vpc_cidr" {
  # CIDR block assigned to the VPC.
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  # CIDR blocks for the public subnets used by EKS and the bastion host.
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "instance_type" {
  # EC2 instance type for the bastion/support instance and node group.
  description = "EC2 instance type for support/bastion instance"
  type        = string
  default     = "t3.micro"
}

variable "node_group_desired_capacity" {
  # Desired number of EKS worker nodes in the managed node group.
  description = "Desired number of EKS managed nodes"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  # Maximum allowed number of worker nodes in the EKS node group.
  description = "Maximum number of EKS managed nodes"
  type        = number
  default     = 3
}

variable "node_group_min_size" {
  # Minimum allowed number of worker nodes in the EKS node group.
  description = "Minimum number of EKS managed nodes"
  type        = number
  default     = 1
}

# Terraform Infrastructure for Sprint 2

This folder contains Terraform configuration to provision AWS resources for Sprint 2:
- VPC, public subnets, Internet Gateway, and route table
- EKS cluster and managed node group
- EC2 support/bastion instance
- Remote state backend configuration for S3

## Usage

1. Copy the example variables file:
   ```sh
   cp terraform.tfvars.example terraform.tfvars
   ```

2. If the backend bucket and DynamoDB lock table already exist, initialize Terraform with backend config:
   ```sh
   terraform init \
     -backend-config="bucket=webapp-pipeline-terraform-state" \
     -backend-config="key=global/sprint2/terraform.tfstate" \
     -backend-config="region=ap-south-1" \
     -backend-config="dynamodb_table=webapp-pipeline-terraform-lock"
   ```

3. If the backend resources do not yet exist, bootstrap them first:
   ```sh
   bash bootstrap-backend.sh
   ```

4. Plan and apply using the initialized backend:
   ```sh
   terraform plan -var-file=terraform.tfvars
   terraform apply -auto-approve -var-file=terraform.tfvars
   ```

## Jenkins integration

The root `Jenkinsfile` has been extended to execute Terraform provisioning stages before building and publishing the application Docker image. Configure AWS credentials in Jenkins and pass the `TF_APPLY` parameter to enable automated state changes.

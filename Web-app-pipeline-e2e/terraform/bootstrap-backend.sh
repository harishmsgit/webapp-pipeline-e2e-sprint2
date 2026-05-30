#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")"

# Create tfvars from example if needed.
if [ ! -f terraform.tfvars ]; then
  cp terraform.tfvars.example terraform.tfvars
  echo "Created terraform.tfvars from terraform.tfvars.example"
fi

cat <<'EOF'
This helper bootstraps remote backend resources in two phases:
  1. initialize Terraform without a remote backend
  2. apply the config locally to create S3/DynamoDB backend resources
  3. reinitialize Terraform with the remote backend configured
EOF

original_backend_file="backend.tf"
backup_backend_file="backend.tf.disabled"

if [ -f "$original_backend_file" ]; then
  mv "$original_backend_file" "$backup_backend_file"
fi

trap 'if [ -f "$backup_backend_file" ]; then mv "$backup_backend_file" "$original_backend_file"; fi' EXIT INT TERM

terraform init
terraform apply -auto-approve -var-file=terraform.tfvars \
  -target=aws_s3_bucket.terraform_state \
  -target=aws_dynamodb_table.terraform_lock \
  -target=aws_iam_role.terraform_backend_role \
  -target=aws_iam_role_policy.terraform_s3_dynamo

if [ -f "$backup_backend_file" ]; then
  mv "$backup_backend_file" "$original_backend_file"
fi

terraform init -reconfigure \
  -backend-config="bucket=webapp-pipeline-terraform-state" \
  -backend-config="key=global/sprint2/terraform.tfstate" \
  -backend-config="region=ap-south-1" \
  -backend-config="dynamodb_table=webapp-pipeline-terraform-lock"

echo "Terraform backend bootstrap complete."

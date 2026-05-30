# End-to-End DevOps Pipeline for a Web Application with CI/CD

## Sprint 1 Deliverables

This workspace implements Sprint 1: Architecture Design, Dockerization, and Jenkins Setup.

### What is included
- Application architecture design for AWS-based deployment
- Dockerized web application with a working `Dockerfile`
- Jenkins pipeline definition in `Jenkinsfile`
- Jenkins setup guidance for AWS EC2, required plugins, and AWS/EKS access
- Git integration details for CI triggers

## Sprint 2 Deliverables

This workspace now includes Sprint 2 infrastructure provisioning and Jenkins integration.

### What is included
- Terraform scripts for AWS resources: VPC, subnets, security groups, EKS cluster, managed node group, and EC2 instance
- S3 remote state backend with DynamoDB locking
- Jenkins pipeline stages for Terraform init, plan, and optional apply
- Example Terraform variables in `terraform/terraform.tfvars.example`

### What is intentionally excluded
- Kubernetes deployment manifests beyond EKS cluster provisioning
- Production-ready IAM hardening beyond managed policy attachments
- Monitoring and logging stacks (Prometheus/Grafana)

## Directory structure

- `app/`
  - `server.js` — lightweight Node.js web application
  - `package.json` — app metadata and start script
- `Dockerfile` — Docker image build instructions
- `Jenkinsfile` — Jenkins declarative pipeline for Sprint 1 and Sprint 2
- `terraform/` — Terraform infrastructure provisioning for Sprint 2
- `architecture-sprint1.md` — architecture design and AWS integration plan
- `jenkins-setup.md` — Jenkins setup and plugin configuration
- `.gitignore` — ignores node artifacts and Terraform state files

## Local validation

1. Build locally:
   ```sh
   docker build -t web-app-sprint1:latest .
   ```
2. Run locally:
   ```sh
   docker run -p 3000:3000 web-app-sprint1:latest
   ```
3. Validate with Docker Compose:
   ```sh
   docker compose config
   docker compose up --build
   ```
4. Open `http://localhost:3000`

## Terraform validation

1. Change into the Terraform folder:
   ```sh
   cd terraform
   ```
2. Initialize with backend config:
   ```sh
   terraform init \
     -backend-config="bucket=webapp-pipeline-terraform-state" \
     -backend-config="key=global/sprint2/terraform.tfstate" \
     -backend-config="region=ap-south-1" \
     -backend-config="dynamodb_table=webapp-pipeline-terraform-lock"
   ```
3. Plan the infrastructure:
   ```sh
   terraform plan -var-file=terraform.tfvars.example
   ```
4. Apply the infrastructure:
   ```sh
   terraform apply -auto-approve -var-file=terraform.tfvars.example
   ```

## Jenkins usage

1. Create a Jenkins multibranch pipeline job or a pipeline job with branch support.
2. Point it to this repository.
3. Allow Jenkins to run using the `Jenkinsfile` in the repo root.
4. Configure AWS credentials and ECR permissions in Jenkins.
5. Use the `TF_APPLY` build parameter to enable Terraform apply during the job.

### Branch behavior
- The pipeline automatically detects the current branch via `BRANCH_NAME`.
- Docker image tags include the branch name and build ID.
- This enables CI execution across multiple branches with branch-specific artifacts.

## Notes

Sprint 1 and Sprint 2 are now combined in this repo: the application is Dockerized, and Jenkins can provision AWS infrastructure through Terraform before building and pushing the container image.

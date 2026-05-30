# Terraform configuration for Sprint 2 infrastructure provisioning.
# This file provisions an AWS VPC, public subnets, an internet gateway,
# security groups, an EKS cluster, an EKS managed node group, and a bastion EC2 host.
# It also creates IAM roles and attaches required policies for EKS control plane and workers.
# Use the variables defined in variables.tf and the remote state backend configured in backend.tf.

# Configure the AWS provider for Terraform.
provider "aws" {
  # Use the AWS region passed in from variables.tf.
  region = var.aws_region
}

# Query available availability zones in the selected AWS region.
data "aws_availability_zones" "available" {
  # Only return zones that are currently available.
  state = "available"
}

# Create the IAM assume role policy document for the EKS cluster control plane.
data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    # Allow the EKS service to assume this role.
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    # Allow STS assume role for EKS.
    actions = ["sts:AssumeRole"]
  }
}

# Create the IAM assume role policy document for the EKS worker nodes.
data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    # Allow the EC2 service to assume this role.
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    # Allow STS assume role for EC2 worker nodes.
    actions = ["sts:AssumeRole"]
  }
}

# Lookup the latest Amazon Linux 2 AMI for the bastion host.
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    # Match the Amazon Linux 2 AMI name pattern.
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Create the VPC for the EKS cluster and supporting resources.
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    # Tag the VPC with a name derived from the cluster name.
    Name = "${var.cluster_name}-vpc"
  }
}

# Create the internet gateway attached to the VPC.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

# Create public subnets in the selected availability zones.
resource "aws_subnet" "public" {
  # Create one subnet per CIDR block provided.
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.cluster_name}-public-${count.index + 1}"
  }
}

# Create a public route table for the VPC.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

# Add a default route to the internet gateway.
resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate each public subnet with the public route table.
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create a security group for the EKS control plane.
resource "aws_security_group" "eks_cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS cluster control plane security group"
  vpc_id      = aws_vpc.main.id

  egress {
    # Allow all outbound traffic from the EKS control plane.
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-cluster-sg"
  }
}

# Create a security group for EKS worker nodes.
resource "aws_security_group" "eks_nodes" {
  name        = "${var.cluster_name}-nodes-sg"
  description = "EKS worker node security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    # Allow communication between nodes in the same group.
    description = "Allow all worker-to-worker"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    # Allow SSH access to the bastion host / worker nodes.
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # Allow HTTP access from the public internet.
    description = "Allow HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    # Allow all outbound traffic from worker nodes.
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-nodes-sg"
  }
}

# Create the IAM role for the EKS cluster control plane.
resource "aws_iam_role" "eks_cluster_role" {
  name               = "${var.cluster_name}-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json
}

# Attach the Amazon EKS cluster policy to the cluster IAM role.
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach the Amazon EKS service policy to the cluster IAM role.
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# Create a Terraform backend IAM role for S3 and DynamoDB state access.
data "aws_iam_policy_document" "terraform_backend_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "terraform_backend_role" {
  name               = var.terraform_backend_role_name
  assume_role_policy = data.aws_iam_policy_document.terraform_backend_assume_role.json
}

resource "aws_iam_role_policy" "terraform_s3_dynamo" {
  name = "terraform-backend-access-policy"
  role = aws_iam_role.terraform_backend_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.tf_state_bucket}"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${var.tf_state_bucket}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:UpdateItem"]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.tf_state_lock_table}"
      }
    ]
  })
}

# Option: attach the backend permissions to an existing role (e.g., instanceRole)
resource "aws_iam_role_policy" "attach_instance_role_backend" {
  name = "terraform-backend-access-instance-role"
  role = var.backend_attached_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.tf_state_bucket}"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${var.tf_state_bucket}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:UpdateItem"]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.tf_state_lock_table}"
      }
    ]
  })
}

# Create the IAM role for EKS worker nodes.
resource "aws_iam_role" "eks_node_role" {
  name               = "${var.cluster_name}-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json
}

# Attach worker node permissions for EKS.
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach the AWS VPC CNI policy for EKS node networking.
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Attach permission for the nodes to access ECR images.
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Create the EKS cluster control plane.
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    # Use the public subnets for the EKS cluster.
    subnet_ids = aws_subnet.public[*].id
    # Attach the EKS control plane security group.
    security_group_ids = [aws_security_group.eks_cluster.id]
    # Allow public access to the Kubernetes API server.
    endpoint_public_access = true
    public_access_cidrs    = ["0.0.0.0/0"]
  }

  # Enable core EKS cluster logging types.
  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,
  ]
}

# Create an EKS managed node group for worker nodes.
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    # Set desired, minimum, and maximum worker nodes.
    desired_size = var.node_group_desired_capacity
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  instance_types = [var.instance_type]
  capacity_type  = "ON_DEMAND"
}

# Create a bastion EC2 instance for support and access.
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.eks_nodes.id]
  associate_public_ip_address = true

  tags = {
    Name = "${var.cluster_name}-bastion"
  }
}

# Create the S3 bucket used by Terraform remote state.
#
# This resource is bootstrapped before remote backend initialization.
# Use `terraform init -backend=false` to provision this bucket and the
# DynamoDB table locally, then reinitialize with the remote backend.
resource "aws_s3_bucket" "terraform_state" {
  bucket = var.tf_state_bucket
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "${var.cluster_name}-terraform-state"
  }
}

# Create the DynamoDB table used to lock Terraform remote state.
resource "aws_dynamodb_table" "terraform_lock" {
  name         = var.tf_state_lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "${var.cluster_name}-terraform-lock"
  }
}

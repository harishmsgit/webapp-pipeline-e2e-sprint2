# Define outputs to expose important infrastructure values after apply.

output "cluster_name" {
  # Return the EKS cluster name created by this configuration.
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  # Return the Kubernetes API endpoint for the EKS cluster.
  description = "EKS API server endpoint"
  value       = aws_eks_cluster.eks.endpoint
}

output "cluster_security_group_id" {
  # Return the security group ID attached to the EKS control plane.
  description = "Security group ID used by the EKS control plane"
  value       = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
}

output "vpc_id" {
  # Return the ID of the VPC that was created.
  description = "ID of the provisioned VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  # Return a list of the public subnet IDs created for the cluster.
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "bastion_public_ip" {
  # Return the bastion host public IP for SSH or support access.
  description = "Public IP of the support EC2 instance"
  value       = aws_instance.bastion.public_ip
}

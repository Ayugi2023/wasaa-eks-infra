# Development-optimized node groups
# Uses smaller instances and more spot instances

resource "aws_eks_node_group" "general_dev" {
  cluster_name    = var.cluster_name
  node_group_name = "ng-general-dev"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  # Use SPOT instances for 70% cost savings
  capacity_type  = "SPOT"
  instance_types = ["t3.medium", "t3a.medium", "t3.large"]  # Smaller instances

  scaling_config {
    desired_size = 1
    max_size     = 2  # Reduced from 3
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  ami_type   = "AL2_x86_64"
  disk_size  = 30  # Reduced from 50GB
  
  labels = {
    "nodegroup-type" = "general"
    "workload"       = "development"
    "arch"           = "amd64"
    "cost-optimized" = "true"
  }
  
  tags = {
    Environment = "development"
    NodeGroup   = "general-dev"
    Name        = "eks-ng-general-dev"
  }
}

# Single microservices node group with smaller instances
resource "aws_eks_node_group" "microservices_dev" {
  cluster_name    = var.cluster_name
  node_group_name = "ng-microservices-dev"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "SPOT"
  instance_types = ["t3.medium", "t3a.medium", "m5.large"]  # Smaller instances

  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  ami_type   = "AL2_x86_64"
  disk_size  = 30
  
  labels = {
    "nodegroup-type" = "microservices"
    "workload"       = "development"
    "arch"           = "amd64"
  }
  
  tags = {
    Environment = "development"
    NodeGroup   = "microservices-dev"
    Name        = "eks-ng-microservices-dev"
  }
}

# Remove memory-intensive node group for development
# This saves ~$100/month

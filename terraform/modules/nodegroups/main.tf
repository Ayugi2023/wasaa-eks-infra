resource "aws_eks_node_group" "general" {
  cluster_name    = var.cluster_name
  node_group_name = "ng-general"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = ["m6i.large"]

  scaling_config {
    desired_size = 1
    max_size     = 20
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  ami_type   = "AL2_x86_64"
  disk_size  = 50
  
  labels = {
    "nodegroup-type" = "general"
    "workload"       = "standard"
    "arch"           = "amd64"
  }
  
  tags = {
    Environment = var.environment
    NodeGroup   = "general"
    Name        = "eks-ng-general"
  }
}

resource "aws_eks_node_group" "memory" {
  cluster_name    = var.cluster_name
  node_group_name = "ng-memory"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = ["r6i.large"]

  scaling_config {
    desired_size = 1
    max_size     = 20
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  ami_type   = "AL2_x86_64"
  disk_size  = 50
  
  labels = {
    "nodegroup-type" = "memory"
    "workload"       = "memory-intensive"
    "arch"           = "amd64"
  }
  
  tags = {
    Environment = var.environment
    NodeGroup   = "memory"
    Name        = "eks-ng-memory"
  }
}

resource "aws_eks_node_group" "graviton" {
  cluster_name    = var.cluster_name
  node_group_name = "ng-graviton"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = ["m6g.large"]

  scaling_config {
    desired_size = 1
    max_size     = 20
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  ami_type   = "AL2_ARM_64"
  disk_size  = 50
  
  labels = {
    "nodegroup-type" = "graviton"
    "workload"       = "cost-sensitive"
    "arch"           = "arm64"
  }
  
  tags = {
    Environment = var.environment
    NodeGroup   = "graviton"
    Name        = "eks-ng-graviton"
  }
}
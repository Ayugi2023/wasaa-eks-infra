resource "aws_eks_node_group" "base" {
  cluster_name    = var.cluster_name
  node_group_name = "ng-base"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  ami_type       = "AL2_x86_64"
  disk_size      = 20
  
  tags = {
    Environment = var.environment
    NodeGroup = "base"
  }
}

resource "aws_eks_node_group" "spot" {
  cluster_name    = var.cluster_name
  node_group_name = "ng-spot"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "SPOT"
  instance_types = ["t3.medium", "t3.large"]

  scaling_config {
    desired_size = 1
    max_size     = 10
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  ami_type       = "AL2_x86_64"
  disk_size      = 20
  
  tags = {
    Environment = var.environment
    NodeGroup = "spot"
  }
}

resource "aws_eks_node_group" "karpenter" {
  cluster_name    = var.cluster_name
  node_group_name = "ng-karpenter"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  ami_type       = "AL2_x86_64"
  disk_size      = 20
  
  tags = {
    Environment = var.environment
    NodeGroup = "karpenter"
  }
}
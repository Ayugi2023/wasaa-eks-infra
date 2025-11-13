resource "aws_eks_node_group" "general" {
  cluster_name    = var.cluster_name
  node_group_name = "ng-general"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  # COST OPTIMIZATION: Use SPOT instances for 70% savings
  capacity_type  = "SPOT"
  instance_types = ["t3.small", "t3a.small", "t2.small"]  # Cheapest trunk-supported instances

  scaling_config {
    desired_size = 3  # Increased for t3.small
    max_size     = 4  # Allow more smaller nodes
    min_size     = 2
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
  }
  
  tags = {
    Environment = var.environment
    NodeGroup   = "general"
    Name        = "eks-ng-general"
  }
}

# COMMENTED OUT EXPENSIVE NODE GROUPS FOR COST OPTIMIZATION
# Uncomment for production later

# resource "aws_eks_node_group" "memory" {
#   cluster_name    = var.cluster_name
#   node_group_name = "ng-memory"
#   node_role_arn   = var.node_role_arn
#   subnet_ids      = var.private_subnet_ids
#
#   capacity_type  = "ON_DEMAND"
#   instance_types = ["r6i.large"]
#
#   scaling_config {
#     desired_size = 0
#     max_size     = 2
#     min_size     = 0
#   }
#
#   update_config {
#     max_unavailable = 1
#   }
#
#   ami_type   = "AL2_x86_64"
#   disk_size  = 50
#   
#   labels = {
#     "nodegroup-type" = "memory"
#     "workload"       = "memory-intensive"
#     "arch"           = "amd64"
#   }
#   
#   tags = {
#     Environment = var.environment
#     NodeGroup   = "memory"
#     Name        = "eks-ng-memory"
#   }
# }

resource "aws_eks_node_group" "microservices" {
  cluster_name    = var.cluster_name
  node_group_name = "ng-microservices"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids

  capacity_type  = "SPOT"
  instance_types = ["t3.small", "t3a.small", "t2.small"]  # Cheapest trunk-supported instances

  scaling_config {
    desired_size = 3  # Increased for t3.small
    max_size     = 4  # Allow more smaller nodes  
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

  ami_type   = "AL2_x86_64"
  disk_size  = 30  # Reduced from 50GB
  
  labels = {
    "nodegroup-type" = "microservices"
    "workload"       = "microservices"
    "arch"           = "amd64"
  }
  
  tags = {
    Environment = var.environment
    NodeGroup   = "microservices"
    Name        = "eks-ng-microservices"
  }
}
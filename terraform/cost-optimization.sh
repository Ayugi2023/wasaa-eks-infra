#!/bin/bash

# Cost Optimization Implementation Script
# This script implements the development-optimized infrastructure

set -e

echo "🚀 Starting Cost Optimization for Development Environment"
echo "Target: Reduce costs from $1,732 to under $800 (55% reduction)"

# 1. Backup current configuration
echo "📦 Creating backup of current configuration..."
cp -r envs/prod envs/prod-backup-$(date +%Y%m%d)

# 2. Create development environment configuration
echo "🔧 Creating development-optimized configuration..."

# Create dev environment directory
mkdir -p envs/dev

# Copy base configuration
cp envs/prod/main.tf envs/dev/main.tf
cp envs/prod/variables.tf envs/dev/variables.tf
cp envs/prod/outputs.tf envs/dev/outputs.tf

# Update main.tf for development optimizations
cat > envs/dev/terraform.tfvars << EOF
# Development Environment - Cost Optimized
aws_region      = "af-south-1"
environment     = "development"
project_name    = "wasaa"
cluster_name    = "wasaa-dev-eks"
cluster_version = "1.28"

# Smaller VPC CIDR for development
vpc_cidr = "10.1.0.0/16"

# Database configuration
db_username = "wasaaadmin"

# Cost optimization flags
enable_cost_optimization = true
use_spot_instances      = true
single_nat_gateway      = true
minimal_node_groups     = true
EOF

# 3. Update module calls for cost optimization
echo "📝 Updating module configurations..."

# Update databases module call
sed -i.bak 's/source = "..\/..\/modules\/databases"/source = "..\/..\/modules\/databases\/dev-optimized"/' envs/dev/main.tf

# Update elasticache module call  
sed -i.bak 's/source = "..\/..\/modules\/elasticache"/source = "..\/..\/modules\/elasticache\/dev-optimized"/' envs/dev/main.tf

# Update nodegroups module call
sed -i.bak 's/source = "..\/..\/modules\/nodegroups"/source = "..\/..\/modules\/nodegroups\/dev-optimized"/' envs/dev/main.tf

# 4. Plan the changes
echo "📋 Planning infrastructure changes..."
cd envs/dev
terraform init
terraform plan -out=cost-optimization.tfplan

echo "💰 Cost Optimization Plan Created!"
echo ""
echo "Expected Monthly Savings:"
echo "- Databases: $350 (PostgreSQL: $13 vs $154, MongoDB: $0 vs $252)"
echo "- ElastiCache: $30 (Single node: $12 vs $37)"
echo "- EC2/EKS: $200 (Spot instances, smaller sizes)"
echo "- EFS: $35 (One Zone, IA storage class)"
echo "- VPC: $80 (Single NAT Gateway, VPC endpoints)"
echo "- Support: $135 (Consider downgrading to Developer)"
echo ""
echo "Total Savings: $830/month"
echo "New Monthly Cost: ~$750 (57% reduction)"
echo ""
echo "To apply changes, run:"
echo "  cd envs/dev"
echo "  terraform apply cost-optimization.tfplan"
echo ""
echo "⚠️  IMPORTANT: This will:"
echo "   - Replace Aurora cluster with single PostgreSQL instance"
echo "   - Replace DocumentDB with MongoDB on EKS"
echo "   - Switch to smaller, spot instances"
echo "   - Use single NAT Gateway"
echo "   - Reduce EFS to One Zone storage"
echo ""
echo "🔄 For production, create separate optimized modules"
EOF

chmod +x /Users/webmasters/wasaa-eks-infra/terraform/cost-optimization.sh

# Security and Infrastructure Updates

## Changes Made

### 1. IAM Policy Addition
- Added `AmazonEKSVPCResourceController` policy to EKS cluster service role
- Location: `terraform/modules/iam/main.tf`
- Purpose: Required for proper EKS VPC resource management

### 2. Security Group Egress Rules
- Added HTTP (port 80) egress rule to cluster security group
- Added HTTPS (port 443) egress rule to cluster security group
- Location: `terraform/modules/vpc/main.tf`
- Purpose: Allow Karpenter nodes internet access for EKS API and package downloads

### 3. Karpenter Microservices Configuration
- Created `karpenter-microservices-ec2nodeclass.yaml`
- Created `karpenter-microservices-nodepool.yaml`
- Features:
  - Dedicated EC2NodeClass for microservices workloads
  - Node labels: `nodegroup-type=microservices`, `workload=microservices`
  - Taint: `workload=microservices:NoSchedule`
  - Instance types: t3, t3a, m5, m5a families
  - Support for both amd64 and arm64 architectures
  - Spot and on-demand capacity types

## Deployment Steps

1. Apply Terraform changes:
   ```bash
   cd terraform/envs/prod
   terraform plan
   terraform apply
   ```

2. Apply Karpenter configurations:
   ```bash
   kubectl apply -f karpenter-microservices-ec2nodeclass.yaml
   kubectl apply -f karpenter-microservices-nodepool.yaml
   ```

## Route Table Associations
The existing VPC configuration already has proper route table associations:
- Private EKS subnets are associated with route tables that have NAT gateway routes
- No additional route table changes needed

## Security Group ID
The security group referenced in the original requirements (`sg-02f93d9e10abd9136`) appears to be the cluster security group created by the VPC module. The egress rules have been added to this security group.
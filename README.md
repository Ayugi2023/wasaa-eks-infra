# WASAA EKS Infrastructure

## Overview
This repository contains Terraform modules and Ansible playbooks for deploying a production-ready EKS cluster on AWS.

## Structure
```
├── terraform/
│   ├── envs/prod/          # Production environment
│   └── modules/            # Reusable Terraform modules
└── ansible/
    ├── playbooks/          # Ansible playbooks
    └── roles/              # Ansible roles
```

## Quick Start

### Deploy Infrastructure
```bash
cd terraform/envs/prod
terraform init
terraform plan
terraform apply
```

### Configure Kubernetes
```bash
cd ansible
ansible-playbook playbooks/site.yml
```

## Components
- **VPC**: Multi-AZ setup with public/private subnets
- **EKS Cluster**: Managed Kubernetes cluster
- **Node Groups**: Auto-scaling worker nodes
- **RDS**: PostgreSQL database
- **S3**: Object storage
- **CloudFront**: CDN distribution
- **Monitoring**: Prometheus & Grafana
- **Security**: Pod Security Standards & RBAC
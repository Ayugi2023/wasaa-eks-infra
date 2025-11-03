# ECR OIDC Integration Setup

## Overview
This setup allows EKS pods to pull ECR images without manually managing ECR secrets. It uses OIDC (OpenID Connect) to authenticate pods with AWS IAM roles.

## What was created:

### 1. IAM Role
- **Role Name:** `wasaa-prod-eks-ecr-oidc-role`
- **ARN:** `arn:aws:iam::561810056018:role/wasaa-prod-eks-ecr-oidc-role`
- **Permissions:** Can pull images from ECR repositories in us-east-1 and af-south-1

### 2. Service Accounts
- **Name:** `ecr-service-account` 
- **Created in:** All wasaa-* namespaces
- **Annotation:** `eks.amazonaws.com/role-arn=arn:aws:iam::561810056018:role/wasaa-prod-eks-ecr-oidc-role`

## How to use:

### Option 1: Update Helm Charts (Recommended)
Add the following to your deployment spec in helm charts:

```yaml
spec:
  template:
    spec:
      serviceAccountName: ecr-service-account
      containers:
      - name: your-container
        image: 561810056018.dkr.ecr.us-east-1.amazonaws.com/your-service:tag
        # No imagePullSecrets needed!
```

### Option 2: Update existing deployments
```bash
kubectl patch deployment your-deployment -n your-namespace -p '{"spec":{"template":{"spec":{"serviceAccountName":"ecr-service-account"}}}}'
```

### Option 3: Remove ECR secrets (after testing)
Once confirmed working, you can remove the manual ECR secrets:
```bash
kubectl delete secret ecr-secret -n your-namespace
```

## Benefits:
- ✅ No more manual ECR token refresh
- ✅ No more ECR secrets management  
- ✅ Automatic authentication via OIDC
- ✅ Works across both us-east-1 and af-south-1 ECR repositories
- ✅ Follows AWS security best practices

## Testing:
1. Update a deployment to use `serviceAccountName: ecr-service-account`
2. Remove `imagePullSecrets` from the deployment
3. Verify the pod can pull ECR images successfully

## Troubleshooting:
- Ensure the service account exists in your namespace
- Check the service account has the correct role annotation
- Verify the ECR repository exists and the image tag is correct
- Check pod logs for authentication errors

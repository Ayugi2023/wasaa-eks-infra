# ArgoCD Setup Guide for WASAA Platform

This guide explains how to deploy the complete WASAA platform using ArgoCD GitOps after installing ArgoCD in your Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (EKS, GKE, AKS, or self-managed)
- `kubectl` configured to access your cluster
- ArgoCD CLI (`argocd`) installed (optional but recommended)
- GitHub credentials with access to:
  - `web-masters-ke/wasaa-infra` (infrastructure configs)
  - `web-masters-ke/wasaa-chat-helm-charts` (Helm charts)

## Step 1: Install ArgoCD

### Option A: Using ArgoCD CLI (Recommended)

```bash
# Install ArgoCD CLI
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# Install ArgoCD in Kubernetes
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### Option B: Using Helm

```bash
# Add ArgoCD Helm repo
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD
helm install argocd argo/argo-cd --namespace argocd --create-namespace

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

## Step 2: Access ArgoCD UI

### Get Initial Admin Password

```bash
# Get the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Port Forward to Access UI

```bash
# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access ArgoCD UI at: https://localhost:8080
# Username: admin
# Password: [from above command]
```

## Step 3: Add Repository Credentials

ArgoCD needs credentials to access your private GitHub repositories.

### Using ArgoCD CLI

```bash
# Login to ArgoCD (replace with your admin password)
argocd login localhost:8080 --username admin --password YOUR_ADMIN_PASSWORD

# Add wasaa-infra repository
argocd repo add https://github.com/web-masters-ke/wasaa-infra \
  --username YOUR_GITHUB_USERNAME \
  --password YOUR_GITHUB_TOKEN \
  --name wasaa-infra

# Add wasaa-helm-charts repository
argocd repo add https://github.com/web-masters-ke/wasaa-chat-helm-charts \
  --username YOUR_GITHUB_USERNAME \
  --password YOUR_GITHUB_TOKEN \
  --name wasaa-helm-charts
```

### Using ArgoCD UI

1. Go to **Settings** → **Repositories**
2. Click **+ CONNECT REPO**
3. Fill in:
   - **Repository URL**: `https://github.com/web-masters-ke/wasaa-infra`
   - **Username**: Your GitHub username
   - **Password**: Your GitHub personal access token
4. Click **CONNECT**
5. Repeat for `https://github.com/web-masters-ke/wasaa-chat-helm-charts`

## Step 4: Create WASAA Applications Project

### Using ArgoCD CLI

```bash
# Create the project
kubectl apply -f projects/wasaa-applications.yaml
```

### Using ArgoCD UI

1. Go to **Settings** → **Projects**
2. Click **+ NEW PROJECT**
3. Use the configuration from `projects/wasaa-applications.yaml`

## Step 5: Deploy Root Application

Choose your environment (developer/staging/production):

### For Developer Environment

```bash
# Deploy developer environment
kubectl apply -f developer-root.yaml
```

### For Production Environment

```bash
# Deploy production environment
kubectl apply -f production-root.yaml
```

### For Staging Environment

```bash
# Deploy staging environment
kubectl apply -f staging-root.yaml
```

## Step 6: Monitor Deployment Progress

### Using ArgoCD UI

1. Go to **Applications** in the ArgoCD dashboard
2. You should see:
   - `wasaa-developer-root` (or your chosen environment)
   - Infrastructure applications (cert-manager, nginx-ingress, etc.)
   - Monitoring stack (prometheus, grafana, loki, etc.)
   - WASAA microservices (16 services)

### Using ArgoCD CLI

```bash
# List all applications
argocd app list

# Get status of specific app
argocd app get wasaa-developer-root
```

## Step 7: Verify Deployment

### Check Pod Status

```bash
# Check all pods in wasaa namespaces
kubectl get pods -A | grep wasaa

# Check monitoring pods
kubectl get pods -n monitoring

# Check ingress pods
kubectl get pods -n ingress-nginx
```

### Check Services

```bash
# Check all services
kubectl get svc -A | grep -E "(wasaa|monitoring|ingress)"

# Check ingress resources
kubectl get ingress -A
```

### Access Applications

```bash
# Get ingress URLs
kubectl get ingress -A

# Port forward services for local access (if needed)
kubectl port-forward svc/wasaa-gateway-service -n wasaa-gateway-service 8080:80
```

## Step 8: Access Monitoring Dashboard

```bash
# Get Grafana admin password
kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d

# Port forward Grafana
kubectl port-forward svc/grafana -n monitoring 3000:80

# Access Grafana at: http://localhost:3000
# Username: admin
# Password: [from above]
```

## Troubleshooting

### Common Issues

1. **Repository Connection Failed**
   - Verify GitHub credentials and token permissions
   - Ensure token has `repo` scope

2. **Application Sync Failed**
   - Check ArgoCD application logs: `kubectl logs -n argocd deployment/argocd-server`
   - Verify repository URLs and branch names

3. **Pods Not Starting**
   - Check pod logs: `kubectl logs -n <namespace> <pod-name>`
   - Verify environment-specific values in `environments/` folder

4. **Ingress Not Working**
   - Check ingress controller: `kubectl get pods -n ingress-nginx`
   - Verify LoadBalancer service has external IP

### Useful Commands

```bash
# Force sync an application
argocd app sync wasaa-developer-root

# Get application details
argocd app get wasaa-developer-root --hard-refresh

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-server -f

# Restart ArgoCD components
kubectl rollout restart deployment/argocd-server -n argocd
```

## Architecture Overview

Your deployment follows this hierarchy:

```
wasaa-developer-root (App-of-Apps)
├── Infrastructure (cert-manager, nginx-ingress, databases)
├── Monitoring (prometheus, grafana, loki, jaeger)
└── Microservices (16 WASAA services)
```

All configurations are environment-specific and stored in the `environments/` folder.

## Next Steps

- Configure external DNS for ingress access
- Set up SSL certificates with cert-manager
- Configure monitoring alerts and dashboards
- Set up CI/CD pipelines for automatic deployments

For detailed configuration options, see the environment-specific values in the `environments/` folder.
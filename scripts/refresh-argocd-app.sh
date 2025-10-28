#!/bin/bash

# Force refresh ArgoCD application to clear cache
echo "Refreshing ArgoCD wasaa-microservices application..."

# Method 1: Using kubectl to delete and recreate the application
kubectl delete application wasaa-microservices -n argocd --ignore-not-found=true

# Wait a moment
sleep 5

# Recreate the application
kubectl apply -f /Users/webmasters/wasaa-eks-infra/argocd/applications/wasaa-microservices/root-wasaa-microservices.yaml

echo "Application refreshed. Check ArgoCD UI for sync status."
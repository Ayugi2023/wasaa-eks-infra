#!/bin/bash

echo "Fixing ArgoCD deployment exclusion issue..."

# Update ArgoCD ConfigMap to ensure Deployments are included
kubectl patch configmap argocd-cm -n argocd --type merge -p '{
  "data": {
    "resource.inclusions": "- apiGroups:\n  - \"\"\n  kinds:\n  - Pod\n  - Service\n  - ConfigMap\n  - Secret\n  - PersistentVolumeClaim\n- apiGroups:\n  - apps\n  kinds:\n  - Deployment\n  - ReplicaSet\n  - StatefulSet\n- apiGroups:\n  - networking.k8s.io\n  kinds:\n  - Ingress\n- apiGroups:\n  - autoscaling\n  kinds:\n  - HorizontalPodAutoscaler"
  }
}'

echo "Restarting ArgoCD server to apply changes..."
kubectl rollout restart deployment/argocd-server -n argocd
kubectl rollout restart deployment/argocd-application-controller -n argocd

echo "Waiting for ArgoCD to restart..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-application-controller -n argocd --timeout=300s

echo "ArgoCD configuration updated. Deployments should now be managed."
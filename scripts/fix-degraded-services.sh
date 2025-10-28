#!/bin/bash

echo "Fixing degraded microservices..."

# Fix 1: Create missing secrets by copying from rds-secret
NAMESPACES=(
    "wasaa-shorts-service"
    "wasaa-admin-service"
    "wasaa-affiliate-service"
    "wasaa-apps-service"
    "wasaa-audit-service"
    "wasaa-calls-service"
    "wasaa-chama-service"
    "wasaa-contact-service"
    "wasaa-developer-service"
    "wasaa-fundraiser-service"
    "wasaa-gift-service"
    "wasaa-livestream-service"
    "wasaa-media-service"
    "wasaa-message-service"
    "wasaa-moderation-service"
    "wasaa-notification-service"
    "wasaa-status-service"
    "wasaa-support-service"
    "wasaa-user-service"
    "wasaa-wallet-service"
)

for ns in "${NAMESPACES[@]}"; do
    echo "Fixing secrets in $ns..."
    
    # Create service-specific db secret
    SERVICE_NAME=$(echo $ns | sed 's/wasaa-//' | sed 's/-service//')
    
    kubectl create secret generic "wasaa-${SERVICE_NAME}-db-secret" \
        --from-literal=username="$(kubectl get secret rds-secret -n $ns -o jsonpath='{.data.username}' | base64 -d)" \
        --from-literal=password="$(kubectl get secret rds-secret -n $ns -o jsonpath='{.data.password}' | base64 -d)" \
        -n $ns --dry-run=client -o yaml | kubectl apply -f -
    
    # Create redis secret
    kubectl create secret generic "wasaa-redis-secret" \
        --from-literal=password="$(kubectl get secret rds-secret -n $ns -o jsonpath='{.data.password}' | base64 -d)" \
        -n $ns --dry-run=client -o yaml | kubectl apply -f -
        
    echo "Fixed secrets for $ns"
done

echo "Restarting failed deployments..."

# Restart all deployments to pick up new secrets
kubectl rollout restart deployment -l app --all-namespaces | grep wasaa

echo "Fix completed. Monitor pod status with: kubectl get pods -A | grep wasaa"
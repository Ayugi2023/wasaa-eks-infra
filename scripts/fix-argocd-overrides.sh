#!/bin/bash

# Fix ArgoCD ConfigMap/Deployment Override Issues
# This script adds ignoreDifferences and proper sync options to all microservice applications

ARGOCD_APPS_DIR="/Users/webmasters/wasaa-eks-infra/argocd/applications/wasaa-microservices"

echo "Fixing ArgoCD applications to prevent ConfigMap/Deployment overrides..."

# List of microservice applications to fix
MICROSERVICES=(
    "wasaa-admin-service-app.yaml"
    "wasaa-adsmanager-app.yaml"
    "wasaa-affiliate-service-app.yaml"
    "wasaa-analytics-service-app.yaml"
    "wasaa-apps-service-app.yaml"
    "wasaa-audit-service-app.yaml"
    "wasaa-calls-service-app.yaml"
    "wasaa-chama-service-app.yaml"
    "wasaa-contact-service-app.yaml"
    "wasaa-developer-service-app.yaml"
    "wasaa-escrow-service-app.yaml"
    "wasaa-fundraiser-service-app.yaml"
    "wasaa-gift-service-app.yaml"
    "wasaa-groups-service-app.yaml"
    "wasaa-kafka-service-app.yaml"
    "wasaa-livestream-service-app.yaml"
    "wasaa-marketplace-service-app.yaml"
    "wasaa-media-service-app.yaml"
    "wasaa-message-service-app.yaml"
    "wasaa-moderation-service-app.yaml"
    "wasaa-notification-service-app.yaml"
    "wasaa-shorts-service-app.yaml"
    "wasaa-status-service-app.yaml"
    "wasaa-storefront-service-app.yaml"
    "wasaa-support-service-app.yaml"
    "wasaa-wallet-service-app.yaml"
    "wasaa-web-service-app.yaml"
)

for app in "${MICROSERVICES[@]}"; do
    app_file="$ARGOCD_APPS_DIR/$app"
    
    if [[ -f "$app_file" ]]; then
        echo "Processing $app..."
        
        # Check if the file already has ignoreDifferences
        if grep -q "ignoreDifferences" "$app_file"; then
            echo "  - $app already has ignoreDifferences configured"
            continue
        fi
        
        # Check if the file has the basic syncPolicy structure we expect
        if grep -q "syncOptions:" "$app_file"; then
            # Add ignoreDifferences and enhanced sync options
            sed -i '' '/syncOptions:/a\
      - RespectIgnoreDifferences=true\
      - ApplyOutOfSyncOnly=true\
    retry:\
      limit: 5\
      backoff:\
        duration: 10s\
        factor: 2\
        maxDuration: 3m\
  ignoreDifferences:\
    - group: apps\
      kind: Deployment\
      jsonPointers:\
        - /spec/replicas\
        - /spec/template/spec/containers/0/image\
    - group: ""\
      kind: ConfigMap\
      jsonPointers:\
        - /data' "$app_file"
            
            echo "  - Updated $app with ignoreDifferences configuration"
        else
            echo "  - WARNING: $app does not have expected syncOptions structure"
        fi
    else
        echo "  - WARNING: $app_file not found"
    fi
done

echo ""
echo "Fix completed! Summary of changes:"
echo "1. Added RespectIgnoreDifferences=true to sync options"
echo "2. Added ApplyOutOfSyncOnly=true to prevent unnecessary syncs"
echo "3. Added retry configuration for failed syncs"
echo "4. Added ignoreDifferences for Deployment replicas and container images"
echo "5. Added ignoreDifferences for ConfigMap data to prevent overrides"
echo ""
echo "Next steps:"
echo "1. Review the changes in git: git diff"
echo "2. Commit and push the changes"
echo "3. ArgoCD will automatically pick up the new configurations"
echo "4. Monitor applications for proper sync behavior"
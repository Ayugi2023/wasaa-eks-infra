#!/bin/bash

# Fix YAML formatting issues caused by the previous script
ARGOCD_APPS_DIR="/Users/webmasters/wasaa-eks-infra/argocd/applications/wasaa-microservices"

echo "Fixing YAML formatting issues..."

for file in "$ARGOCD_APPS_DIR"/*.yaml; do
    if [[ -f "$file" ]]; then
        # Fix the corrupted line that combines /data with CreateNamespace
        sed -i '' 's|- /data      - CreateNamespace=true|- /data|g' "$file"
        echo "Fixed $(basename "$file")"
    fi
done

echo "YAML formatting fix completed!"
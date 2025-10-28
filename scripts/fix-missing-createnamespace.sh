#!/bin/bash

# Fix missing CreateNamespace=true in sync options
ARGOCD_APPS_DIR="/Users/webmasters/wasaa-eks-infra/argocd/applications/wasaa-microservices"

echo "Adding missing CreateNamespace=true to sync options..."

for file in "$ARGOCD_APPS_DIR"/*.yaml; do
    if [[ -f "$file" ]]; then
        # Check if file has syncOptions but missing CreateNamespace
        if grep -q "syncOptions:" "$file" && ! grep -q "CreateNamespace=true" "$file"; then
            # Add CreateNamespace=true as first sync option
            sed -i '' '/syncOptions:/a\
      - CreateNamespace=true' "$file"
            echo "Fixed $(basename "$file")"
        fi
    fi
done

echo "CreateNamespace fix completed!"
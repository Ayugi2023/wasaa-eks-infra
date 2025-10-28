#!/bin/bash

# Create missing ECR repositories for microservices
REGION="us-east-1"

MISSING_REPOS=(
    "wasaa-livestream-service"
    "wasaa-groups-service" 
    "wasaa-storefront-service"
    "wasaa-affiliate-service"
    "wasaa-escrow-service"
    "wasaa-adsmanager"
)

echo "Creating missing ECR repositories..."

for repo in "${MISSING_REPOS[@]}"; do
    echo "Creating ECR repository: $repo"
    aws ecr create-repository \
        --repository-name "$repo" \
        --region "$REGION" \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256 || echo "Repository $repo might already exist"
done

echo "ECR repositories created. Now building and pushing placeholder images..."

# Create a simple placeholder Dockerfile
cat > /tmp/Dockerfile << 'EOF'
FROM node:18-alpine
WORKDIR /app
RUN echo 'console.log("Service starting...");' > index.js
RUN echo '{"name":"placeholder","version":"1.0.0","main":"index.js"}' > package.json
EXPOSE 3000
CMD ["node", "index.js"]
EOF

# Build and push placeholder images
for repo in "${MISSING_REPOS[@]}"; do
    echo "Building placeholder image for $repo..."
    docker build -t "$repo:latest" /tmp/
    
    # Tag and push to ECR
    aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "561810056018.dkr.ecr.$REGION.amazonaws.com"
    docker tag "$repo:latest" "561810056018.dkr.ecr.$REGION.amazonaws.com/$repo:latest"
    docker push "561810056018.dkr.ecr.$REGION.amazonaws.com/$repo:latest"
done

echo "Placeholder images pushed to ECR"
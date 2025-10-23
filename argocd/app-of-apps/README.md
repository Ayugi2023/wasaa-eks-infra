# WasaaChat App of Apps

This Helm chart manages the deployment of all WasaaChat services using ArgoCD's App of Apps pattern.

## Environment-Specific Configuration

The chart supports multiple environments with separate configuration files:

- `values-developer.yaml` - Development environment
- `values-staging.yaml` - Staging environment  
- `values-production.yaml` - Production environment

## Usage

Deploy to a specific environment using:

```bash
# Deploy to development
helm install wasaa-app-of-apps . -f values-developer.yaml

# Deploy to staging
helm install wasaa-app-of-apps . -f values-staging.yaml

# Deploy to production
helm install wasaa-app-of-apps . -f values-production.yaml
```

## Configuration

### Environment Differences

Each environment has its own:
- Namespace naming conventions (dev uses base names, staging adds `-staging` suffix, production adds `-prod` suffix)
- Environment-specific value files referenced by the ArgoCD applications

### Common Configuration

The base `values.yaml` file contains common defaults that can be overridden by environment-specific files.

### Namespace Strategy

- **Developer**: Uses simple namespace names (e.g., `wasaa-chat-service`)
- **Staging**: Adds `-staging` suffix (e.g., `wasaa-chat-service-staging`)  
- **Production**: Adds `-prod` suffix (e.g., `wasaa-chat-service-prod`)

This ensures clear separation between environments while maintaining consistent service naming.

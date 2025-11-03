# ArgoCD Configuration Updates

## Changes Made

### 1. Resource Inclusions Updated
Added `ServiceAccount` and `Application` resources to ArgoCD resource inclusions to eliminate "excluded in settings" warnings.

**File**: `argocd-cm-configmap.yaml`

**Key Changes**:
- Added `ServiceAccount` to monitored resources
- Added `Application` resources for proper app-of-apps management
- Maintains existing resource exclusions for performance

### 2. Apply Configuration
To apply this configuration to the cluster:

```bash
kubectl apply -f /Users/webmasters/wasaa-eks-infra/argocd/argocd-cm-configmap.yaml
kubectl rollout restart statefulset/argocd-application-controller -n argocd
```

### 3. Impact
- Eliminates "ServiceAccount excluded" warnings in ArgoCD applications
- Enables proper management of child applications by root app
- Reduces OutOfSync issues caused by resource exclusions

## Files Updated
- `argocd-cm-configmap.yaml` - ArgoCD server configuration
- `README-ARGOCD-CONFIG.md` - This documentation

## Deployment
This configuration should be applied after any ArgoCD installation or upgrade to maintain consistent resource monitoring.

# ArgoCD and Helm Integration Fix

## Problem
ConfigMaps and Deployments in Helm charts were being overridden by ArgoCD, causing:
- Configuration changes not persisting
- Deployment rollbacks to previous states
- Helm and ArgoCD management conflicts

## Root Causes Identified
1. **Missing ignoreDifferences**: ArgoCD was treating Helm-managed resources as out-of-sync
2. **Improper Sync Options**: Missing `RespectIgnoreDifferences` and `ApplyOutOfSyncOnly`
3. **App-of-Apps Conflicts**: Parent application overriding child application configurations

## Fixes Applied

### 1. Added ignoreDifferences Configuration
```yaml
ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
      - /spec/replicas
      - /spec/template/spec/containers/0/image
      - /spec/template/metadata/annotations
  - group: ""
    kind: ConfigMap
    jsonPointers:
      - /data
  - group: ""
    kind: Secret
    jsonPointers:
      - /data
  - group: autoscaling
    kind: HorizontalPodAutoscaler
    jsonPointers:
      - /spec/minReplicas
      - /spec/maxReplicas
      - /status
```

### 2. Enhanced Sync Options
```yaml
syncOptions:
  - CreateNamespace=true
  - RespectIgnoreDifferences=true
  - ApplyOutOfSyncOnly=true
```

### 3. Added Retry Configuration
```yaml
retry:
  limit: 5
  backoff:
    duration: 10s
    factor: 2
    maxDuration: 3m
```

## Files Modified
- `wasaa-user-service-app.yaml` ✅
- `wasaa-gateway-service-app.yaml` ✅
- `root-wasaa-microservices.yaml` ✅

## Automation Script
Run the fix script to apply changes to all microservices:
```bash
./scripts/fix-argocd-overrides.sh
```

## Template for New Services
Use `argocd/templates/microservice-app-template.yaml` for new microservice applications.

## Verification Steps
1. Check ArgoCD UI for sync status
2. Verify ConfigMaps persist after Helm updates
3. Confirm Deployments don't rollback unexpectedly
4. Monitor application health and sync frequency

## Best Practices Going Forward
1. Always include `ignoreDifferences` for Helm-managed resources
2. Use `RespectIgnoreDifferences=true` in sync options
3. Set appropriate retry policies for failed syncs
4. Monitor ArgoCD logs for sync conflicts
5. Use the provided template for new microservices

## Troubleshooting
If issues persist:
1. Check ArgoCD server logs: `kubectl logs -n argocd deployment/argocd-server`
2. Verify Helm release status: `helm list -A`
3. Compare resource manifests: `kubectl diff -f <manifest>`
4. Force refresh application: `argocd app get <app-name> --refresh`
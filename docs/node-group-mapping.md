# Node Group Workload Mapping

## Node Groups Configuration

### 🧩 ng-general (x86) - `m6i.large`
**Purpose**: Steady workloads, APIs, always-on traffic
**Scaling**: 1-20 nodes (desired: 1)
**Labels**:
- `nodegroup-type=general`
- `workload=standard`
- `arch=amd64`

**Services**:
- wasaa-wallet-service
- wasaa-web-service
- wasaa-user-service
- wasaa-status-service
- wasaa-contact-service
- wasaa-calls-service
- wasaa-gateway-service
- wasaa-groups-service
- wasaa-storefront-service
- wasaa-notification-service
- wasaa-fundraiser-service

### 🧠 ng-memory (x86) - `r6i.large`
**Purpose**: Heavy memory consumers (media, livestream)
**Scaling**: 1-20 nodes (desired: 1)
**Labels**:
- `nodegroup-type=memory`
- `workload=memory-intensive`
- `arch=amd64`

**Services**:
- wasaa-media-service
- wasaa-livestream-service
- wasaa-shorts-service

### ⚙️ ng-graviton (ARM) - `m6g.large`
**Purpose**: Cost-sensitive, low-traffic, staff-only apps
**Scaling**: 1-20 nodes (desired: 1)
**Labels**:
- `nodegroup-type=graviton`
- `workload=cost-sensitive`
- `arch=arm64`

**Services**:
- wasaa-admin-service
- wasaa-audit-service
- wasaa-support-service
- wasaa-affiliate-service
- wasaa-moderation-service
- wasaa-apps-service
- wasaa-developer-service
- wasaa-gift-service

## Helm Chart Integration

Use these node selectors in your Helm values.yaml:

```yaml
# For general workloads
nodeSelector:
  nodegroup-type: general

# For memory-intensive workloads
nodeSelector:
  nodegroup-type: memory

# For cost-sensitive workloads
nodeSelector:
  nodegroup-type: graviton
```

## ArgoCD Application Example

```yaml
helm:
  values: |
    nodeSelector:
      nodegroup-type: general
```
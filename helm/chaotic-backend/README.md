# Chaotic Backend Helm Chart

## Install

```bash
helm install chaotic-backend ./helm/chaotic-backend
```

## Key Settings

- **Replicas**: 3 (auto-scales 3-15)
- **Resources**: 200m CPU / 256Mi memory requests, 1000m CPU / 1024Mi limits
- **Health Checks**: Startup (60 failures), Liveness (60s delay), Readiness (30s delay)
- **Service**: LoadBalancer (creates ALB via AWS Load Balancer Controller)

## Upgrade

```bash
helm upgrade chaotic-backend ./helm/chaotic-backend
```

## Uninstall

```bash
helm uninstall chaotic-backend
```

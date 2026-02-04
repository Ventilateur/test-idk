# Operations Guide

## Common Commands

### Check Status
```bash
kubectl get pods
kubectl get svc
kubectl get hpa
```

### View Logs
```bash
kubectl logs -l app.kubernetes.io/name=chaotic-backend --tail=100
```

### Get Service URL
```bash
kubectl get svc chaotic-backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Troubleshooting

### Pods Not Starting
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### ALB Not Created
- Check AWS Load Balancer Controller: `kubectl get deployment -n kube-system aws-load-balancer-controller`
- Check controller logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`

### High Error Rate
- Check pod logs
- Scale up: `kubectl scale deployment chaotic-backend --replicas=5`

### Access CloudWatch Logs
```bash
aws logs tail /aws/eks/chaotic-backend-cluster/chaotic-backend --follow
```

## Testing

```bash
# Smoke tests
./scripts/smoke-tests.sh

# Chaos tests
./scripts/chaos-test.sh
```


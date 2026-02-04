# Chaotic Backend Deployment

## Disclaimer

Q: Is it AI generated?
A: Absolutely, this is a lot of requirements for a mere test. I can do it myself given enough time and effort, but we have a constraint here.

Q: Have you reviewed the code?  
A: Yes.

Q: Does it work?
A: Most likely not at first try due to a lot of AWS dependencies, and I don't plan to use my personal AWS account for a test. However, I'd be happy to walk you through the process.

Q: Does this fulfill all the requirements?
A: No, the observability and TLS parts are not there yet. They require more sophisticated setup. I'm happy to walk you through it.

Q: Would you do this in production?
A: Absolutely not. I'd spend more time and iterate this over multiple steps.

## Quick Start

### Prerequisites
- AWS CLI configured
- Terraform >= 1.0
- kubectl >= 1.28
- Helm >= 3.0

### Deploy

```bash
# 1. Configure (optional)
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if needed

# 2. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 3. Configure kubectl
aws eks update-kubeconfig --region us-west-2 --name chaotic-backend-cluster

# 4. Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm repo update
ALB_ROLE_ARN=$(cd terraform && terraform output -raw alb_controller_role_arn)
CLUSTER_NAME=$(cd terraform && terraform output -raw cluster_name)
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ALB_ROLE_ARN

# 5. Deploy application
cd ..
helm install chaotic-backend ./helm/chaotic-backend

# 6. Get service URL
kubectl get svc chaotic-backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Architecture

```
Internet → ALB (K8s managed) → EKS Cluster → Pods (3+ replicas, auto-scaling)
                                              ↓
                                         CloudWatch Logs
```

## What's Included

- **VPC**: 2 AZs, public/private subnets, NAT Gateway
- **EKS**: Managed cluster with 2-4 nodes (t3.medium)
- **ALB**: Created by Kubernetes via AWS Load Balancer Controller
- **Helm Chart**: Deployment with health checks, HPA, PDB
- **Monitoring**: CloudWatch logs

## Project Structure

```
terraform/          # Infrastructure (VPC, EKS, IAM)
helm/              # Kubernetes deployment
scripts/           # Smoke tests, chaos tests
```

## Cleanup

```bash
cd terraform
terraform destroy
```

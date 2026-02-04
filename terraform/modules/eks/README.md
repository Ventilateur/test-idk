# EKS Module

Creates EKS cluster, node groups, security groups, and IAM roles.

## Resources

- EKS cluster (Kubernetes 1.28)
- Node group (2-4 nodes, t3.medium, on-demand)
- Security groups (cluster + nodes)
- IAM roles (cluster, nodes, ALB controller)
- CloudWatch log group

## Outputs

- `cluster_name`, `cluster_endpoint`
- `alb_controller_role_arn` (for AWS Load Balancer Controller)

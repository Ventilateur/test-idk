output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "helm_install_command" {
  description = "Command to install Helm chart"
  value       = "helm install chaotic-backend ../helm/chaotic-backend"
}

output "get_load_balancer_dns" {
  description = "Command to get load balancer DNS after Helm deployment"
  value       = "kubectl get svc chaotic-backend -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
}


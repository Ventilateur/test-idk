# Networking Module
module "networking" {
  source = "./modules/networking"

  project_name = var.project_name
}

# EKS Cluster Module
module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
}

# Security Module
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  cluster_id   = module.eks.cluster_id
}

# Observability Module
module "observability" {
  source = "./modules/observability"

  project_name = var.project_name
  cluster_name = module.eks.cluster_name
  cluster_id   = module.eks.cluster_id
}


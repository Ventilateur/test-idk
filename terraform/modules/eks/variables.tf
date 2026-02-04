variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs (for EKS nodes)"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs (for EKS cluster endpoints and ALB)"
  type        = list(string)
}


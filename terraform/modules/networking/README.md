# Networking Module

Creates VPC, subnets, Internet Gateway, and NAT Gateway.

## Resources

- VPC (10.0.0.0/16)
- 2 Public subnets (for ALB, NAT Gateway)
- 2 Private subnets (for EKS nodes)
- Internet Gateway
- NAT Gateway (single, cost optimization)
- Route tables

## Outputs

- `vpc_id`
- `public_subnet_ids`
- `private_subnet_ids`

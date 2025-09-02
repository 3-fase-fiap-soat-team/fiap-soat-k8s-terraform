output "vpc_id" {
  description = "ID da VPC criada"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block da VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = module.vpc.private_subnet_ids
}

output "availability_zones" {
  description = "Availability Zones utilizadas"
  value       = module.vpc.availability_zones
}

output "internet_gateway_id" {
  description = "ID do Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

# Futuro: Outputs do EKS
# output "cluster_endpoint" {
#   description = "Endpoint do cluster EKS"
#   value       = module.eks.cluster_endpoint
# }

# output "cluster_security_group_id" {
#   description = "Security group do cluster EKS"
#   value       = module.eks.cluster_security_group_id
# }

# output "cluster_certificate_authority_data" {
#   description = "Certificado do cluster EKS"
#   value       = module.eks.cluster_certificate_authority_data
# }

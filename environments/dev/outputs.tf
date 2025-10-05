# === VPC Outputs (VPC Padrão AWS Academy) ===
output "vpc_id" {
  description = "ID da VPC padrão (compatível com AWS Academy)"
  value       = data.aws_vpc.default.id
}

output "vpc_cidr_block" {
  description = "CIDR block da VPC"
  value       = data.aws_vpc.default.cidr_block
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas descobertas automaticamente"
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas descobertas automaticamente"
  value       = local.private_subnet_ids
}

output "available_subnets" {
  description = "Todas as subnets disponíveis na VPC"
  value       = local.available_subnets
}

output "rds_fallback_subnets" {
  description = "Subnets de fallback para compatibilidade com RDS"
  value       = local.rds_subnet_ids
}

# === EKS Outputs ===
output "cluster_id" {
  description = "ID do cluster EKS"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = module.eks.cluster_endpoint
  sensitive   = false
}

output "cluster_version" {
  description = "Versão do Kubernetes"
  value       = module.eks.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Certificado do cluster EKS"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = false
}

output "cluster_security_group_id" {
  description = "Security group do cluster EKS"
  value       = module.eks.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group dos nodes EKS"
  value       = module.eks.node_security_group_id
}

output "oidc_issuer_url" {
  description = "URL do OIDC issuer para IRSA"
  value       = module.eks.oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN do OIDC provider"
  value       = module.eks.oidc_provider_arn
}

output "node_groups" {
  description = "Informações dos node groups"
  value       = module.eks.node_groups
}

# === Configuração kubectl ===
output "kubectl_config_command" {
  description = "Comando para configurar kubectl"
  value       = module.eks.kubectl_config
}

# === Connection Info ===
output "kubeconfig_info" {
  description = "Informações para configurar kubeconfig"
  value = {
    cluster_name     = module.eks.cluster_name
    cluster_endpoint = module.eks.cluster_endpoint
    cluster_ca_data  = module.eks.cluster_certificate_authority_data
    aws_region       = var.aws_region
  }
  sensitive = false
}

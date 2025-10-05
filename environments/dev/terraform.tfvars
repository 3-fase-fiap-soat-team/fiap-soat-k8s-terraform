# ==============================================================================
# CONFIGURAÇÃO EKS - AWS ACADEMY OPTIMIZED
# ==============================================================================
# Configuração otimizada para AWS Academy com auto-discovery de VPC e IAM roles
# ==============================================================================

# Projeto
project_name = "fiap-soat"
environment  = "dev"

# EKS Cluster
cluster_name    = "fiap-soat-eks-dev"
cluster_version = "1.30"

# Região AWS
aws_region = "us-east-1"

# Node Groups Configuration
node_groups = {
  general = {
    instance_types = ["t3.micro"]
    capacity_type  = "ON_DEMAND"
    min_size       = 1
    max_size       = 3
    desired_size   = 2
  }
}

# Usar subnets públicas para nodes (economia de NAT Gateway)
use_public_subnets_for_nodes = true

# ==============================================================================
# SECURITY GROUPS: CRIAR NOVOS (RECOMENDADO)
# ==============================================================================
# O Terraform criará security groups específicos para o EKS com as regras
# necessárias para comunicação entre cluster e nodes.
#
# IMPORTANTE: Não reutilize security groups do RDS para o EKS!
# Eles têm requisitos de rede completamente diferentes.
# ==============================================================================
create_security_groups = true

# Se você quiser reutilizar SGs existentes (NÃO RECOMENDADO), descomente:
# create_security_groups     = false
# cluster_security_group_id  = "sg-xxxxx"
# node_security_group_id     = "sg-yyyyy"

# Add-ons do EKS (compatíveis com Kubernetes 1.30)
cluster_addons = {
  kube-proxy = {
    version = "v1.30.3-eksbuild.5"
  }
  vpc-cni = {
    version = "v1.18.5-eksbuild.1"
  }
  coredns = {
    version = "v1.11.3-eksbuild.2"
  }
}

# Configuração de acesso ao cluster
endpoint_config = {
  private_access      = true
  public_access       = true
  public_access_cidrs = ["0.0.0.0/0"]  # Aberto para desenvolvimento (AWS Academy)
}

# Tags
tags = {
  Project     = "fiap-soat-fase3"
  Environment = "dev"
  ManagedBy   = "terraform"
  Owner       = "rs94458"
  Budget      = "aws-academy-50usd"
  Team        = "3-fase-fiap-soat-team"
}

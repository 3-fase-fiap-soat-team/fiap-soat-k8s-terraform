# FIAP SOAT - EKS Infrastructure
# Environment: Development
# AWS Academy optimized configuration

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend será configurado posteriormente com bucket S3
  # backend "s3" {
  #   bucket         = "fiap-soat-terraform-state-1756788008"
  #   key            = "k8s/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "fiap-soat-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "fiap-soat-fase3"
      Environment = var.environment
      ManagedBy   = "terraform"
      Owner       = "rs94458"
      Budget      = "aws-academy-50usd"
    }
  }
}

# Strategy: Get VPC and Subnets from existing RDS instance
# AWS Academy voclabs role doesn't have ec2:DescribeVpcs permission,
# but we can get VPC info from RDS
data "aws_db_instance" "existing" {
  db_instance_identifier = "fiap-soat-db"
}

# Data sources para subnets disponíveis (usando subnets do RDS)
data "aws_db_subnet_group" "existing" {
  name = data.aws_db_instance.existing.db_subnet_group
}

# Get subnet details to filter by availability zone
data "aws_subnet" "rds_subnets" {
  for_each = toset(data.aws_db_subnet_group.existing.subnet_ids)
  id       = each.value
}

# Configuração robusta de subnets para AWS Academy
locals {
  # Pegar VPC ID e subnets do RDS
  vpc_id = data.aws_db_subnet_group.existing.vpc_id
  
  # Subnets do RDS subnet group
  rds_subnets = data.aws_db_subnet_group.existing.subnet_ids
  
  # CRITICAL: EKS não suporta us-east-1e
  # Filtrar subnets para excluir us-east-1e (EKS unsupported AZ)
  eks_supported_subnets = [
    for subnet_id, subnet in data.aws_subnet.rds_subnets :
    subnet_id if subnet.availability_zone != "us-east-1e"
  ]
  
  # Validação: Garantir que temos pelo menos 2 subnets em AZs diferentes
  subnet_count = length(local.eks_supported_subnets)
  
  # Distribuir subnets: usar subnets filtradas como públicas para simplicidade no AWS Academy
  public_subnet_ids  = local.eks_supported_subnets
  private_subnet_ids = local.eks_supported_subnets
}

# Módulo EKS
module "eks" {
  source = "../../modules/eks"

  # Configuração do cluster
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  project_name    = var.project_name
  environment     = var.environment

  # Rede (VPC e subnets do RDS - compatível com AWS Academy)
  vpc_id             = local.vpc_id
  private_subnet_ids = local.private_subnet_ids
  public_subnet_ids  = local.public_subnet_ids

  # Configuração de subnets para nodes
  use_public_subnets_for_nodes = var.use_public_subnets_for_nodes

  # Security Groups - Reutilizar ou criar
  create_security_groups    = var.create_security_groups
  cluster_security_group_id = var.cluster_security_group_id
  node_security_group_id    = var.node_security_group_id

  # Node Groups
  node_groups = var.node_groups

  # IRSA e add-ons
  enable_irsa    = true
  cluster_addons = var.cluster_addons

  # Configuração de acesso
  endpoint_config = var.endpoint_config

  tags = var.tags

  depends_on = [data.aws_db_instance.existing, data.aws_db_subnet_group.existing]
}

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

# Strategy: Use default VPC (more reliable in AWS Academy)
data "aws_vpc" "default" {
  default = true
}

# Data sources para subnets disponíveis na VPC padrão
data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Configuração robusta de subnets para AWS Academy
locals {
  # Descobrir subnets automaticamente ou usar fallback
  available_subnets = length(data.aws_subnets.available.ids) > 0 ? data.aws_subnets.available.ids : []

  # Se não encontrar subnets, criar configuração básica
  subnet_count = length(local.available_subnets)

  # Distribuir subnets: usar todas como públicas para simplicidade no AWS Academy
  public_subnet_ids  = local.subnet_count > 0 ? local.available_subnets : []
  private_subnet_ids = local.subnet_count > 2 ? slice(local.available_subnets, 1, local.subnet_count) : local.available_subnets

  # Fallback para subnets conhecidas do RDS se necessário
  rds_subnet_ids = [
    "subnet-0c00fd754c4fe4305",
    "subnet-0c5f846c7a41656d4",
    "subnet-05296f706c91a1df8",
    "subnet-0c534eacf07fde00c",
    "subnet-01cf476ef5fe31d92",
    "subnet-0f7c2a12c4f68b254"
  ]
}

# Módulo EKS
module "eks" {
  source = "../../modules/eks"

  # Configuração do cluster
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  project_name    = var.project_name
  environment     = var.environment

  # Rede (VPC padrão - compatível com AWS Academy)
  vpc_id             = data.aws_vpc.default.id
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

  depends_on = [data.aws_vpc.default]
}

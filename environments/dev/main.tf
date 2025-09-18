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

# Módulo VPC
module "vpc" {
  source = "../../modules/vpc"

  project_name                 = var.project_name
  environment                  = var.environment
  vpc_cidr                     = var.vpc_cidr
  cluster_name                 = var.cluster_name
  enable_nat_gateway          = var.enable_nat_gateway
  use_public_subnets_for_nodes = var.use_public_subnets_for_nodes

  tags = var.tags
}

# Módulo EKS
module "eks" {
  source = "../../modules/eks"

  # Configuração do cluster
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  project_name    = var.project_name
  environment     = var.environment

  # Rede
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  
  # Configuração de subnets para nodes
  use_public_subnets_for_nodes = var.use_public_subnets_for_nodes

  # Node Groups
  node_groups = var.node_groups

  # IRSA e add-ons
  enable_irsa    = true
  cluster_addons = var.cluster_addons

  # Configuração de acesso
  endpoint_config = var.endpoint_config

  tags = var.tags

  depends_on = [module.vpc]
}

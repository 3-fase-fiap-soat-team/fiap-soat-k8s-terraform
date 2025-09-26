# VPC Module for FIAP SOAT EKS
# AWS Academy optimized configuration

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = "fiap-soat-fase3"
    ManagedBy   = "terraform"
    # Importante para EKS
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = "fiap-soat-fase3"
  }
}

# Zones fixas para AWS Academy (us-east-1)
locals {
  availability_zones = ["us-east-1a", "us-east-1b"]
}

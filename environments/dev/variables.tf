variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "fiap-soat"
}

variable "environment" {
  description = "Ambiente"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block para VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
  default     = "fiap-soat-cluster"
}

variable "cluster_version" {
  description = "Versão do Kubernetes"
  type        = string
  default     = "1.27"
}

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway (custa ~$45/mês!)"
  type        = bool
  default     = false # IMPORTANTE: Desabilitado para AWS Academy
}

variable "node_groups" {
  description = "Configuração dos node groups"
  type = object({
    general = object({
      instance_types = list(string)
      capacity_type  = string
      min_size      = number
      max_size      = number
      desired_size  = number
    })
  })
  default = {
    general = {
      instance_types = ["t3.micro"]  # Mais econômico
      capacity_type  = "ON_DEMAND"   # Previsível para Academy
      min_size      = 1
      max_size      = 2              # Limite baixo para economia
      desired_size  = 1
    }
  }
}

variable "tags" {
  description = "Tags adicionais"
  type        = map(string)
  default = {
    Project      = "fiap-soat-fase3"
    Owner        = "rs94458"
    Budget       = "aws-academy-50usd"
    CostCenter   = "education"
    AutoShutdown = "true"
  }
}

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

variable "use_default_vpc" {
  description = "Usar VPC padrão (mais confiável no AWS Academy)"
  type        = bool
  default     = true
}

variable "fallback_vpc_id" {
  description = "ID da VPC de fallback (se VPC padrão não disponível)"
  type        = string
  default     = "vpc-0bc479b582e33b241" # VPC do RDS para compatibilidade
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

variable "use_public_subnets_for_nodes" {
  description = "Usar public subnets para nodes EKS (economia sem NAT Gateway)"
  type        = bool
  default     = true # Economia para AWS Academy
}

variable "node_groups" {
  description = "Configuração dos node groups"
  type = object({
    general = object({
      instance_types = list(string)
      capacity_type  = string
      min_size       = number
      max_size       = number
      desired_size   = number
    })
  })
  default = {
    general = {
      instance_types = ["t3.micro"] # Mais econômico
      capacity_type  = "ON_DEMAND"  # Previsível para Academy
      min_size       = 1
      max_size       = 2 # Limite baixo para economia
      desired_size   = 1
    }
  }
}

variable "cluster_addons" {
  description = "Add-ons do EKS (apenas gratuitos para AWS Academy)"
  type = map(object({
    version = string
  }))
  default = {
    kube-proxy = {
      version = "v1.27.6-eksbuild.2"
    }
    vpc-cni = {
      version = "v1.15.4-eksbuild.1"
    }
    coredns = {
      version = "v1.10.1-eksbuild.5"
    }
    # Comentado: add-ons pagos que custam dinheiro
    # aws-ebs-csi-driver = {
    #   version = "v1.24.0-eksbuild.1"
    # }
  }
}

variable "endpoint_config" {
  description = "Configuração de acesso ao cluster EKS"
  type = object({
    private_access      = bool
    public_access       = bool
    public_access_cidrs = list(string)
  })
  default = {
    private_access      = true
    public_access       = true
    public_access_cidrs = ["0.0.0.0/0"] # AWS Academy - acesso total para desenvolvimento
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

# ==============================================================================
# SECURITY GROUPS - REUTILIZAR OU CRIAR
# ==============================================================================

variable "create_security_groups" {
  description = "Se true, cria novos security groups. Se false, usa IDs existentes."
  type        = bool
  default     = true # Padrão: criar novos SGs
}

variable "cluster_security_group_id" {
  description = "ID do Security Group existente para o cluster EKS (usado apenas se create_security_groups = false)"
  type        = string
  default     = null
}

variable "node_security_group_id" {
  description = "ID do Security Group existente para os nodes EKS (usado apenas se create_security_groups = false)"
  type        = string
  default     = null
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "fiap-soat"
}

variable "environment" {
  description = "Ambiente (dev, prod)"
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

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway (custa dinheiro!)"
  type        = bool
  default     = false # Desabilitado por padrão para AWS Academy
}

variable "use_public_subnets_for_nodes" {
  description = "Usar public subnets para nodes EKS (economia sem NAT Gateway)"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Usar apenas 1 NAT Gateway para economia"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags adicionais"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "cluster_version" {
  description = "Versão do Kubernetes"
  type        = string
  default     = "1.27"
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts"
  type        = bool
  default     = true
}

variable "use_public_subnets_for_nodes" {
  description = "Use public subnets for EKS nodes (saves NAT Gateway costs)"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs das subnets privadas"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs das subnets públicas"
  type        = list(string)
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
}

variable "environment" {
  description = "Ambiente"
  type        = string
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}

variable "endpoint_config" {
  description = "Configuração de acesso ao cluster"
  type = object({
    private_access      = bool
    public_access       = bool
    public_access_cidrs = list(string)
  })
  default = {
    private_access      = true
    public_access       = true
    public_access_cidrs = ["0.0.0.0/0"] # AWS Academy - acesso total
  }
}

variable "cluster_addons" {
  description = "Add-ons do EKS"
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
  }
}

variable "cluster_security_group_id" {
  description = "ID do Security Group existente para o cluster EKS (opcional - se não fornecido, será criado um novo)"
  type        = string
  default     = null
}

variable "node_security_group_id" {
  description = "ID do Security Group existente para os nodes EKS (opcional - se não fornecido, será criado um novo)"
  type        = string
  default     = null
}

variable "create_security_groups" {
  description = "Se true, cria novos security groups. Se false, usa os IDs fornecidos nas variáveis."
  type        = bool
  default     = true
}

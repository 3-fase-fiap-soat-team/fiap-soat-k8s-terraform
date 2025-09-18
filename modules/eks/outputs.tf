output "cluster_id" {
  description = "ID do cluster EKS"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_security_group_id" {
  description = "ID do security group do cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "Nome da IAM role do cluster (pré-criada do AWS Academy)"
  value       = data.aws_iam_role.cluster_role.name
}

output "cluster_iam_role_arn" {
  description = "ARN da IAM role do cluster (pré-criada do AWS Academy)"
  value       = data.aws_iam_role.cluster_role.arn
}

output "cluster_certificate_authority_data" {
  description = "Dados do certificado da autoridade do cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  description = "Versão do Kubernetes do cluster"
  value       = aws_eks_cluster.main.version
}

output "node_groups" {
  description = "Informações dos node groups"
  value = {
    general = {
      arn            = aws_eks_node_group.general.arn
      status         = aws_eks_node_group.general.status
      capacity_type  = aws_eks_node_group.general.capacity_type
      instance_types = aws_eks_node_group.general.instance_types
      scaling_config = aws_eks_node_group.general.scaling_config
    }
  }
}

output "node_group_iam_role_arn" {
  description = "ARN da IAM role dos node groups (pré-criada do AWS Academy)"
  value       = data.aws_iam_role.node_role.arn
}

output "oidc_issuer_url" {
  description = "URL do OIDC issuer"
  value       = try(aws_eks_cluster.main.identity[0].oidc[0].issuer, null)
}

output "oidc_provider_arn" {
  description = "ARN do OIDC provider para IRSA"
  value       = null  # IRSA desabilitado para AWS Academy
}

output "cluster_primary_security_group_id" {
  description = "ID do security group primário criado pelo EKS"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "node_security_group_id" {
  description = "ID do security group dos nodes"
  value       = aws_security_group.node_group.id
}

# Output para kubectl config
output "kubeconfig_certificate_authority_data" {
  description = "Dados do certificado para kubeconfig"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "kubectl_config" {
  description = "Comando para configurar kubectl"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${aws_eks_cluster.main.name}"
}

#!/bin/bash

# Script de Limpeza do State - AWS Academy Emergency Cleanup
# Remove recursos do state sem tentar deletar da AWS
# Use apenas se não conseguir acessar AWS para deletar

echo "🧹 LIMPEZA EMERGENCIAL DO TERRAFORM STATE"
echo "=========================================="
echo "⚠️  ATENÇÃO: Isso remove do state sem deletar da AWS!"
echo "   Recursos continuarão rodando e custando dinheiro"
echo ""

read -p "Tem certeza que quer continuar? (digite 'sim'): " confirm

if [ "$confirm" != "sim" ]; then
    echo "❌ Operação cancelada"
    exit 1
fi

echo ""
echo "🗑️  Removendo recursos EKS do state..."

# Remover recursos EKS (mais custosos primeiro)
terraform state rm module.eks.aws_eks_node_group.general 2>/dev/null && echo "✅ Node group removido do state"
terraform state rm module.eks.aws_eks_cluster.main 2>/dev/null && echo "✅ Cluster removido do state"
terraform state rm module.eks.aws_launch_template.node_group 2>/dev/null && echo "✅ Launch template removido do state"

# Remover security groups EKS
terraform state rm module.eks.aws_security_group.cluster 2>/dev/null && echo "✅ Security group cluster removido"
terraform state rm module.eks.aws_security_group.node_group 2>/dev/null && echo "✅ Security group nodes removido"

# Remover regras de security group
terraform state rm module.eks.aws_security_group_rule.cluster_ingress_node_https 2>/dev/null
terraform state rm module.eks.aws_security_group_rule.node_group_ingress_cluster_https 2>/dev/null
terraform state rm module.eks.aws_security_group_rule.node_group_ingress_cluster_kubelet 2>/dev/null

echo ""
echo "📋 Estado atual do Terraform:"
terraform state list

echo ""
echo "⚠️  IMPORTANTE:"
echo "   - Recursos ainda estão rodando na AWS!"
echo "   - Você precisa deletar manualmente no Console AWS"
echo "   - URLs importantes:"
echo "     * EKS: https://us-east-1.console.aws.amazon.com/eks/home?region=us-east-1#/clusters"
echo "     * EC2: https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#Instances:"
echo "     * VPC: https://us-east-1.console.aws.amazon.com/vpc/home?region=us-east-1#vpcs:"

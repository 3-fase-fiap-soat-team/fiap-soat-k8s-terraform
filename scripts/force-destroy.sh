#!/bin/bash

# Script para tentar destroy com diferentes estratégias
echo "🔄 TENTATIVAS DE LIMPEZA TERRAFORM"
echo "=================================="

cd /home/rafae/fiap-arch-software/fiap-soat-k8s-terraform/environments/dev

echo "1️⃣ Tentando destroy com refresh=false..."
terraform destroy -auto-approve -refresh=false -target=module.eks 2>&1 | tee destroy_attempt_1.log

if [ $? -eq 0 ]; then
    echo "✅ Sucesso na tentativa 1!"
    exit 0
fi

echo ""
echo "2️⃣ Tentando destroy sem target específico..."
terraform destroy -auto-approve -refresh=false 2>&1 | tee destroy_attempt_2.log

if [ $? -eq 0 ]; then
    echo "✅ Sucesso na tentativa 2!"
    exit 0
fi

echo ""
echo "3️⃣ Tentando remover recursos individualmente..."

# Tentar remover node group primeiro
terraform destroy -auto-approve -refresh=false -target=module.eks.aws_eks_node_group.general 2>&1 | tee destroy_nodegroup.log

# Depois cluster
terraform destroy -auto-approve -refresh=false -target=module.eks.aws_eks_cluster.main 2>&1 | tee destroy_cluster.log

echo ""
echo "📋 Logs salvos em:"
echo "   - destroy_attempt_1.log"
echo "   - destroy_attempt_2.log" 
echo "   - destroy_nodegroup.log"
echo "   - destroy_cluster.log"

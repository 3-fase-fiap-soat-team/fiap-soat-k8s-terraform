#!/bin/bash

# Script para setup rápido do ambiente de desenvolvimento
# Inclui configuração de credenciais AWS Academy

set -e  # Exit on any error

PROJECT_ROOT="/home/rafae/fiap-arch-software/fiap-soat-k8s-terraform"

echo "🚀 Setup do Ambiente de Desenvolvimento FIAP-SOAT"
echo "=================================================="

# Verificar se estamos no diretório correto
if [[ ! -f "README.md" ]] || [[ ! -d "modules" ]]; then
    echo "❌ Execute este script a partir do diretório raiz do projeto"
    exit 1
fi

# Verificar dependências
echo "🔍 Verificando dependências..."

# AWS CLI
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI não encontrado. Instale: https://aws.amazon.com/cli/"
    exit 1
fi

# Terraform
if ! command -v terraform &> /dev/null; then
    echo "⚠️  Terraform não encontrado. Instale: https://terraform.io/"
else
    echo "✅ Terraform encontrado: $(terraform version -json | jq -r '.terraform_version')"
fi

# kubectl
if ! command -v kubectl &> /dev/null; then
    echo "⚠️  kubectl não encontrado. Instale: https://kubernetes.io/docs/tasks/tools/"
else
    echo "✅ kubectl encontrado: $(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')"
fi

echo

# Configurar credenciais AWS
echo "🔑 Configuração de Credenciais AWS Academy"
echo "==========================================="
echo
echo "Escolha uma opção:"
echo "1) Configurar credenciais AWS Academy"
echo "2) Testar credenciais atuais"
echo "3) Pular configuração"
echo
read -p "Opção [1-3]: " choice

case $choice in
    1)
        ./scripts/aws-config.sh
        ;;
    2)
        echo "🧪 Testando credenciais atuais..."
        if aws sts get-caller-identity; then
            echo "✅ Credenciais funcionando!"
        else
            echo "❌ Credenciais não funcionando. Execute: ./scripts/aws-config.sh"
        fi
        ;;
    *)
        echo "⏭️  Pulando configuração de credenciais..."
        ;;
esac

echo
echo "📋 Próximos Passos:"
echo "==================="
echo "1. Para configurar/reconfigurar AWS: ./scripts/aws-config.sh"
echo "2. Para verificar credenciais: aws sts get-caller-identity"
echo "3. Para inicializar Terraform: cd environments/dev && terraform init"
echo "4. Para planejar infraestrutura: terraform plan"
echo "5. Para aplicar infraestrutura: terraform apply"
echo
echo "📝 Documentação: Veja README.md e NEXT-STEPS.md"
echo
echo "✅ Setup concluído!"

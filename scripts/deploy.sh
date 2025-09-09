#!/bin/bash

# Script de deploy para FIAP SOAT - AWS Academy
# Autor: rs94458
# Uso: ./scripts/deploy.sh

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    command -v terraform >/dev/null 2>&1 || error "Terraform não encontrado. Instale: https://terraform.io/"
    command -v kubectl >/dev/null 2>&1 || error "kubectl não encontrado. Instale: https://kubernetes.io/docs/tasks/tools/"
    command -v aws >/dev/null 2>&1 || error "AWS CLI não encontrado. Instale: https://aws.amazon.com/cli/"
    
    log "✅ Dependências verificadas"
}

# Verificar credenciais AWS
check_aws_credentials() {
    log "Verificando credenciais AWS..."
    
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        error "Credenciais AWS não configuradas. Configure com: aws configure"
    fi
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    log "✅ Conectado à conta AWS: $ACCOUNT_ID"
}

# Deploy da infraestrutura
deploy_infrastructure() {
    log "🚀 Iniciando deploy da infraestrutura..."
    
    cd environments/dev
    
    # Inicializar Terraform
    log "Inicializando Terraform..."
    terraform init
    
    # Validar configuração
    log "Validando configuração..."
    terraform validate
    
    # Mostrar plano
    log "Criando plano de execução..."
    terraform plan -out=tfplan
    
    # Confirmar aplicação
    warn "⚠️  ATENÇÃO: Este deploy criará recursos que CUSTAM DINHEIRO na AWS!"
    warn "💰 EKS Control Plane: ~$73/mês"
    warn "💰 Node Group (t3.micro): ~$15/mês"
    warn "💰 Total estimado: ~$88/mês (pode estourar budget AWS Academy!)"
    echo
    read -p "Deseja continuar? (digite 'sim' para confirmar): " confirm
    
    if [ "$confirm" != "sim" ]; then
        error "Deploy cancelado pelo usuário"
    fi
    
    # Aplicar mudanças
    log "Aplicando mudanças..."
    terraform apply tfplan
    
    log "✅ Infraestrutura criada com sucesso!"
    
    cd ../..
}

# Configurar kubectl
configure_kubectl() {
    log "Configurando kubectl..."
    
    CLUSTER_NAME=$(cd environments/dev && terraform output -raw cluster_name)
    AWS_REGION=$(cd environments/dev && terraform output -raw aws_region 2>/dev/null || echo "us-east-1")
    
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
    
    log "✅ kubectl configurado para cluster: $CLUSTER_NAME"
    
    # Verificar conexão
    log "Verificando conexão com cluster..."
    kubectl get nodes
}

# Deploy da aplicação
deploy_application() {
    log "🚀 Fazendo deploy da aplicação..."
    
    # Aplicar manifests
    log "Aplicando manifests Kubernetes..."
    kubectl apply -f manifests/application/
    
    # Aguardar deployment
    log "Aguardando deployment ficar pronto..."
    kubectl wait --for=condition=available --timeout=300s deployment/fiap-soat-app -n fiap-soat
    
    log "✅ Aplicação deployada com sucesso!"
}

# Verificar status
check_status() {
    log "📊 Verificando status do cluster..."
    
    echo
    echo "=== CLUSTER STATUS ==="
    kubectl get nodes -o wide
    
    echo
    echo "=== PODS STATUS ==="
    kubectl get pods -A
    
    echo
    echo "=== SERVICES STATUS ==="
    kubectl get svc -A
    
    echo
    echo "=== FIAP SOAT APP STATUS ==="
    kubectl get all -n fiap-soat
    
    echo
    echo "=== ACCESS INFO ==="
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    
    echo "Aplicação disponível em:"
    echo "  NodePort: http://$NODE_IP:30080"
    echo "  Port-forward: kubectl port-forward svc/fiap-soat-app 3000:80 -n fiap-soat"
}

# Menu principal
main() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "🎯 FIAP SOAT - EKS Deploy Script"
    echo "🏫 AWS Academy Optimized"
    echo "💡 Autor: rs94458"
    echo "=================================================="
    echo -e "${NC}"
    
    check_dependencies
    check_aws_credentials
    
    echo
    echo "Escolha uma opção:"
    echo "1) Deploy completo (infraestrutura + aplicação)"
    echo "2) Apenas infraestrutura"
    echo "3) Apenas aplicação"
    echo "4) Verificar status"
    echo "5) Configurar kubectl"
    echo "6) Sair"
    echo
    
    read -p "Opção: " option
    
    case $option in
        1)
            deploy_infrastructure
            configure_kubectl
            deploy_application
            check_status
            ;;
        2)
            deploy_infrastructure
            configure_kubectl
            ;;
        3)
            deploy_application
            check_status
            ;;
        4)
            check_status
            ;;
        5)
            configure_kubectl
            ;;
        6)
            log "👋 Tchau!"
            exit 0
            ;;
        *)
            error "Opção inválida"
            ;;
    esac
}

# Executar script
main

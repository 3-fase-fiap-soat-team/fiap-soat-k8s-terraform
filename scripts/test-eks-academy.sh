#!/bin/bash

# Test EKS Cluster Creation - AWS Academy Version with Pre-created Roles
# Uses LabEksClusterRole and LabEksNodeRole from AWS Academy

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações para AWS Academy
CLUSTER_NAME="fiap-soat-academy-cluster"
REGION="us-east-1"
LOG_FILE="/tmp/eks-academy-test-$(date +%Y%m%d-%H%M%S).log"
TIMEOUT_MINUTES=30
EKSCTL_PATH="/tmp/eksctl"

# IAM Roles pré-criadas no AWS Academy
CLUSTER_ROLE_ARN="arn:aws:iam::280273007505:role/c173096a4485959l11165982t1w280273-LabEksClusterRole-jiF0LvC4kZ5O"
NODE_ROLE_ARN="arn:aws:iam::280273007505:role/c173096a4485959l11165982t1w280273007-LabEksNodeRole-3PRff1hjVZWU"

# Função para log com timestamp
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Função de cleanup
cleanup() {
    log "🧹 Iniciando limpeza do cluster de teste..."
    
    # Tentar deletar cluster via eksctl
    if [ -f "$EKSCTL_PATH" ]; then
        log "Tentando deletar cluster via eksctl..."
        $EKSCTL_PATH delete cluster --name "$CLUSTER_NAME" --region "$REGION" --wait || true
    fi
    
    # Tentar deletar via AWS CLI
    log "Tentando deletar cluster via AWS CLI..."
    aws eks delete-cluster --name "$CLUSTER_NAME" --region "$REGION" || true
    
    log "🏁 Limpeza concluída!"
}

# Configurar trap para cleanup
trap cleanup EXIT

# Verificar pré-requisitos
log "🔍 Verificando pré-requisitos para AWS Academy..."

# Verificar AWS CLI
if ! command -v aws &> /dev/null; then
    error "AWS CLI não encontrado"
    exit 1
fi

# Verificar credenciais
if ! aws sts get-caller-identity &> /dev/null; then
    error "Credenciais AWS inválidas"
    exit 1
fi

# Verificar eksctl
if [ ! -f "$EKSCTL_PATH" ]; then
    error "eksctl não encontrado em $EKSCTL_PATH"
    exit 1
fi

# Verificar se as roles existem
log "Verificando roles IAM pré-criadas..."
if ! aws iam get-role --role-name "c173096a4485959l11165982t1w280273-LabEksClusterRole-jiF0LvC4kZ5O" &> /dev/null; then
    error "LabEksClusterRole não encontrada"
    exit 1
fi

if ! aws iam get-role --role-name "c173096a4485959l11165982t1w280273007-LabEksNodeRole-3PRff1hjVZWU" &> /dev/null; then
    error "LabEksNodeRole não encontrada"
    exit 1
fi

success "✅ Pré-requisitos verificados - roles IAM encontradas"

# Criar configuração eksctl para AWS Academy
log "📄 Criando configuração eksctl para AWS Academy..."

cat > /tmp/eks-academy-config.yaml << EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${CLUSTER_NAME}
  region: ${REGION}
  version: "1.28"
  tags:
    Environment: academy-test
    Purpose: fiap-soat-test
    AutoDelete: "true"
    Budget: aws-academy-50usd
    Owner: rafael-petherson

# Usar roles IAM pré-criadas do AWS Academy
iam:
  serviceRoleARN: ${CLUSTER_ROLE_ARN}
  withOIDC: false

# Configuração de VPC otimizada para custos
vpc:
  cidr: 10.0.0.0/16
  nat:
    gateway: Disable  # Disable NAT Gateway para economizar custos
  clusterEndpoints:
    privateAccess: false
    publicAccess: true

# Node groups com roles pré-criadas
nodeGroups:
  - name: academy-nodes
    # Usar role pré-criada
    iam:
      instanceRoleARN: ${NODE_ROLE_ARN}
    
    # Configuração de instância para AWS Academy
    instanceType: t3.micro  # Tipo compatível com Academy
    desiredCapacity: 1
    minSize: 1
    maxSize: 1
    
    # Configuração de volume
    volumeSize: 8
    volumeType: gp3
    
    # Configuração de rede - usar subnets públicas para evitar NAT Gateway
    privateNetworking: false
    
    # SSH desabilitado por segurança
    ssh:
      allow: false
    
    # Labels para identificação
    labels:
      Environment: academy
      NodeGroup: academy-nodes
      Project: fiap-soat
    
    # Tags
    tags:
      Environment: academy-test
      AutoShutdown: "true"
      Budget: aws-academy-50usd
      Project: fiap-soat-fase3

# Addons essenciais apenas
addons:
  - name: vpc-cni
    version: latest
  - name: coredns  
    version: latest
  - name: kube-proxy
    version: latest

# CloudWatch logging desabilitado para economizar
cloudWatch:
  clusterLogging:
    enable: []
EOF

log "✅ Configuração criada para AWS Academy"

# Teste 1: Validar configuração
log "🧪 Teste 1: Validando configuração..."

$EKSCTL_PATH create cluster -f /tmp/eks-academy-config.yaml --dry-run

if [ $? -eq 0 ]; then
    success "✅ Configuração válida para AWS Academy!"
    
    log "🚀 Iniciando criação do cluster EKS..."
    timeout ${TIMEOUT_MINUTES}m $EKSCTL_PATH create cluster -f /tmp/eks-academy-config.yaml
    
    if [ $? -eq 0 ]; then
        success "🎉 Cluster EKS criado com sucesso no AWS Academy!"
        
        # Testar acesso ao cluster
        log "🔧 Testando acesso ao cluster..."
        
        # Configurar kubectl
        aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
        
        # Verificar nodes
        kubectl get nodes
        
        # Verificar pods do sistema
        kubectl get pods -n kube-system
        
        success "✅ Cluster totalmente funcional!"
        
        # Mostrar informações do cluster
        log "📊 Informações do cluster:"
        aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query 'cluster.{Name:name,Status:status,Version:version,Endpoint:endpoint}'
        
    else
        error "❌ Falha na criação do cluster"
        exit 1
    fi
else
    error "❌ Configuração inválida"
    exit 1
fi

log "📊 RESUMO DO TESTE EKS ACADEMY"
log "============================="
log "✅ Cluster: $CLUSTER_NAME"
log "🏷️  Roles: Pré-criadas do AWS Academy"
log "💰 Custo: Otimizado (sem NAT Gateway)"
log "🕐 Tempo: $(date)"
log "📝 Log: $LOG_FILE"
log "🏁 Teste concluído com sucesso!"

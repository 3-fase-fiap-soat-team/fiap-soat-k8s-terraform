#!/bin/bash

# Test EKS Cluster Creation Only - AWS Academy Compatible
# Foco específico em testar criação do cluster EKS

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações
CLUSTER_NAME="fiap-soat-test-cluster"
REGION="us-east-1"
LOG_FILE="/tmp/eks-cluster-test-$(date +%Y%m%d-%H%M%S).log"
TIMEOUT_MINUTES=30
EKSCTL_PATH="/tmp/eksctl"

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
log "🔍 Verificando pré-requisitos..."

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

success "✅ Pré-requisitos verificados"

# Tentar criar cluster com eksctl (mais simples para AWS Academy)
log "🚀 Testando criação de cluster EKS com eksctl..."

cat > /tmp/eks-cluster-config.yaml << EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${CLUSTER_NAME}
  region: ${REGION}
  version: "1.28"
  tags:
    Environment: test
    Purpose: academy-test
    AutoDelete: "true"
    Budget: aws-academy-50usd

# Configuração mínima para testar criação
iam:
  withOIDC: false

# Usar fargate se disponível (sem nodes EC2)
fargateProfiles:
  - name: default
    selectors:
      - namespace: default
      - namespace: kube-system

# OU node groups mínimos se fargate não funcionar
nodeGroups:
  - name: test-nodes
    instanceType: t3.micro
    desiredCapacity: 1
    minSize: 1
    maxSize: 1
    volumeSize: 8
    ssh:
      allow: false
    iam:
      withAddonPolicies:
        imageBuilder: false
        autoScaler: false
        externalDNS: false
        certManager: false
        appMesh: false
        ebs: false
        fsx: false
        efs: false
        cloudWatch: false
        albIngress: false
EOF

log "📄 Configuração do cluster criada"

# Teste 1: Tentar criar com Fargate (sem node groups)
log "🧪 Teste 1: Criação com Fargate Profile..."

timeout ${TIMEOUT_MINUTES}m $EKSCTL_PATH create cluster -f /tmp/eks-cluster-config.yaml --dry-run

if [ $? -eq 0 ]; then
    success "✅ Dry-run com Fargate foi bem-sucedido!"
    
    log "🎯 Tentando criação real com Fargate..."
    timeout ${TIMEOUT_MINUTES}m $EKSCTL_PATH create cluster -f /tmp/eks-cluster-config.yaml
    
    if [ $? -eq 0 ]; then
        success "🎉 Cluster EKS criado com sucesso usando Fargate!"
        
        # Testar acesso ao cluster
        log "🔧 Testando acesso ao cluster..."
        aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION"
        
        if [ $? -eq 0 ]; then
            success "✅ Cluster acessível via AWS CLI!"
        else
            warning "⚠️ Cluster criado mas não acessível via AWS CLI"
        fi
    else
        error "❌ Falha na criação do cluster com Fargate"
        exit 1
    fi
else
    error "❌ Dry-run falhou - permissões insuficientes"
    
    # Teste 2: Verificar permissões específicas
    log "🧪 Teste 2: Verificando permissões específicas..."
    
    # Testar permissões EKS
    log "Testando permissão para DescribeCluster..."
    aws eks describe-cluster --name "cluster-inexistente" --region "$REGION" 2>&1 | grep -q "ResourceNotFoundException" && success "✅ Permissão DescribeCluster OK"
    
    # Testar permissões IAM básicas
    log "Testando permissões IAM..."
    aws iam list-roles --max-items 1 &> /dev/null && success "✅ Permissão ListRoles OK" || warning "⚠️ Sem permissão ListRoles"
    
    # Testar permissões EC2
    log "Testando permissões EC2..."
    aws ec2 describe-vpcs --max-items 1 &> /dev/null && success "✅ Permissão DescribeVpcs OK" || warning "⚠️ Sem permissão DescribeVpcs"
    
    error "❌ Permissões insuficientes para criar cluster EKS"
fi

log "📊 RESUMO DO TESTE EKS"
log "===================="
log "🕐 Tempo: $(date)"
log "📝 Log salvo em: $LOG_FILE"
log "🏁 Teste concluído!"

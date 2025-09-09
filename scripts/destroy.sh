#!/bin/bash

# Script para destruir recursos AWS - IMPORTANTE para economia
# Autor: rs94458
# Uso: ./scripts/destroy.sh

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

# Remover aplicação
cleanup_application() {
    log "🧹 Removendo aplicação do Kubernetes..."
    
    if kubectl get namespace fiap-soat >/dev/null 2>&1; then
        kubectl delete -f manifests/application/ --ignore-not-found=true
        kubectl delete namespace fiap-soat --ignore-not-found=true
        log "✅ Aplicação removida"
    else
        log "ℹ️  Namespace fiap-soat não encontrado"
    fi
}

# Destruir infraestrutura
destroy_infrastructure() {
    log "💥 Destruindo infraestrutura..."
    
    cd environments/dev
    
    # Mostrar o que será destruído
    log "Mostrando recursos que serão destruídos..."
    terraform plan -destroy
    
    echo
    warn "⚠️  ATENÇÃO: Esta ação irá DESTRUIR TODOS os recursos!"
    warn "💾 Certifique-se de ter backup de dados importantes!"
    warn "🔥 Esta ação é IRREVERSÍVEL!"
    echo
    
    read -p "Tem certeza que deseja destruir tudo? (digite 'DESTRUIR' para confirmar): " confirm
    
    if [ "$confirm" != "DESTRUIR" ]; then
        error "Destruição cancelada pelo usuário"
    fi
    
    # Destruir recursos
    log "Destruindo recursos..."
    terraform destroy -auto-approve
    
    log "✅ Infraestrutura destruída com sucesso!"
    log "💰 Recursos AWS removidos - custos parados!"
    
    cd ../..
}

# Limpeza completa
cleanup_all() {
    log "🧹 Limpeza completa do ambiente..."
    
    # Limpar contexto kubectl
    if command -v kubectl >/dev/null 2>&1; then
        CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
        if [[ "$CURRENT_CONTEXT" == *"fiap-soat"* ]]; then
            kubectl config delete-context "$CURRENT_CONTEXT" || true
            log "✅ Contexto kubectl removido"
        fi
    fi
    
    # Limpar arquivos temporários
    find . -name "tfplan" -delete 2>/dev/null || true
    find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
    rm -rf environments/dev/.terraform/ 2>/dev/null || true
    
    log "✅ Limpeza completa finalizada"
}

# Verificar status dos recursos
check_resources() {
    log "📊 Verificando recursos AWS restantes..."
    
    echo
    echo "=== EKS CLUSTERS ==="
    aws eks list-clusters --query 'clusters[?contains(@, `fiap-soat`)]' --output table || true
    
    echo
    echo "=== EC2 INSTANCES ==="
    aws ec2 describe-instances \
        --filters "Name=tag:Project,Values=fiap-soat*" \
        --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType}' \
        --output table || true
    
    echo
    echo "=== LOAD BALANCERS ==="
    aws elbv2 describe-load-balancers \
        --query 'LoadBalancers[?contains(LoadBalancerName, `fiap-soat`)].{Name:LoadBalancerName,State:State.Code}' \
        --output table || true
    
    echo
    echo "=== VPCs ==="
    aws ec2 describe-vpcs \
        --filters "Name=tag:Project,Values=fiap-soat*" \
        --query 'Vpcs[].{ID:VpcId,CIDR:CidrBlock,State:State}' \
        --output table || true
}

# Força destruição de recursos órfãos
force_cleanup() {
    warn "🚨 LIMPEZA FORÇADA - Use apenas se terraform destroy falhar!"
    
    read -p "Tem certeza? (digite 'FORCAR' para confirmar): " confirm
    
    if [ "$confirm" != "FORCAR" ]; then
        error "Limpeza forçada cancelada"
    fi
    
    log "🔥 Iniciando limpeza forçada..."
    
    # Listar e deletar clusters EKS
    CLUSTERS=$(aws eks list-clusters --query 'clusters[?contains(@, `fiap-soat`)]' --output text)
    for cluster in $CLUSTERS; do
        warn "Deletando cluster EKS: $cluster"
        aws eks delete-cluster --name "$cluster" || true
    done
    
    # Aguardar clusters serem deletados
    for cluster in $CLUSTERS; do
        log "Aguardando cluster $cluster ser deletado..."
        aws eks wait cluster-deleted --name "$cluster" || true
    done
    
    # Deletar node groups primeiro (se existirem)
    # aws eks list-nodegroups --cluster-name fiap-soat-cluster --query 'nodegroups' --output text | xargs -n1 aws eks delete-nodegroup --cluster-name fiap-soat-cluster --nodegroup-name
    
    warn "⚠️  Limpeza forçada concluída. Verifique o console AWS para recursos órfãos."
}

# Menu principal
main() {
    echo -e "${RED}"
    echo "=================================================="
    echo "💥 FIAP SOAT - Destroy Script"
    echo "💰 AWS Academy Cost Saver"
    echo "⚠️  PERIGO: Esta ferramenta DESTRÓI recursos!"
    echo "=================================================="
    echo -e "${NC}"
    
    # Verificar se terraform existe
    if [ ! -d "environments/dev/.terraform" ]; then
        warn "Terraform não inicializado. Execute deploy.sh primeiro."
    fi
    
    echo
    echo "Escolha uma opção:"
    echo "1) 🗑️  Remover apenas aplicação K8s"
    echo "2) 💥 Destruir infraestrutura completa"
    echo "3) 🧹 Limpeza completa (app + infra + cache)"
    echo "4) 📊 Verificar recursos restantes"
    echo "5) 🚨 Limpeza forçada (emergência)"
    echo "6) ❌ Sair"
    echo
    
    read -p "Opção: " option
    
    case $option in
        1)
            cleanup_application
            ;;
        2)
            cleanup_application
            destroy_infrastructure
            ;;
        3)
            cleanup_application
            destroy_infrastructure
            cleanup_all
            ;;
        4)
            check_resources
            ;;
        5)
            force_cleanup
            ;;
        6)
            log "👋 Saindo sem destruir recursos"
            warn "💰 Lembre-se: recursos AWS custam dinheiro!"
            exit 0
            ;;
        *)
            error "Opção inválida"
            ;;
    esac
    
    echo
    log "🎉 Operação concluída!"
    warn "💡 Dica: Sempre verifique o console AWS para confirmar que não há recursos órfãos cobrando!"
}

# Executar script
main

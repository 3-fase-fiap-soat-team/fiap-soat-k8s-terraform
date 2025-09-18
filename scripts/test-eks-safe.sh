#!/bin/bash

# Script de teste seguro para EKS com timeout automático
# AWS Academy Compatible - Usa roles IAM pré-criadas
# Evita custos excessivos no AWS Academy limitando tempo de execução
# 
# Roles IAM utilizadas:
# - Cluster: c173096a4485959l11165982t1w280273-LabEksClusterRole-jiF0LvC4kZ5O  
# - Node: c173096a4485959l11165982t1w280273007-LabEksNodeRole-3PRff1hjVZWU

set -e  # Exit on any error

# Configurações
TERRAFORM_DIR="/home/rafae/fiap-arch-software/fiap-soat-k8s-terraform/environments/dev"
MAX_RUNTIME_MINUTES=${1:-120}  # Default: 2 horas, pode ser passado como parâmetro
CLUSTER_NAME="fiap-soat-cluster"
LOG_FILE="/tmp/eks-test-$(date +%Y%m%d-%H%M%S).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de log
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

# Função de limpeza (sempre executada)
cleanup() {
    log "🧹 Iniciando limpeza automática..."
    
    cd "$TERRAFORM_DIR"
    
    # Verificar se há recursos para destruir
    if terraform show -json 2>/dev/null | jq -e '.values.root_module.resources | length > 0' >/dev/null 2>&1; then
        warning "⚠️  Recursos detectados! Executando terraform destroy..."
        
        # Destroy com timeout próprio (30 minutos max)
        timeout 1800 terraform destroy -auto-approve -var-file="terraform.tfvars" 2>&1 | tee -a "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            success "✅ Recursos destruídos com sucesso!"
        else
            error "❌ Erro na destruição automática. Verifique manualmente!"
            error "📋 Comandos para limpeza manual:"
            error "   cd $TERRAFORM_DIR"
            error "   terraform destroy -auto-approve"
        fi
    else
        log "ℹ️  Nenhum recurso encontrado para destruir"
    fi
    
    # Mostrar resumo de custos estimados
    show_cost_summary
}

# Função para mostrar resumo de custos
show_cost_summary() {
    local runtime_hours=$(echo "scale=2; $runtime_minutes / 60" | bc)
    local estimated_cost=$(echo "scale=4; $runtime_hours * 0.11" | bc)
    
    log "💰 RESUMO DE CUSTOS ESTIMADOS"
    log "================================"
    log "⏱️  Tempo de execução: ${runtime_minutes} minutos (${runtime_hours}h)"
    log "💵 Custo estimado: ~\$${estimated_cost} USD"
    log "📊 Orçamento restante: ~\$$(echo "50 - $estimated_cost" | bc) USD"
    log "📋 Log completo salvo em: $LOG_FILE"
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log "🔍 Verificando pré-requisitos..."
    
    # Verificar se está no diretório correto
    if [ ! -f "$TERRAFORM_DIR/main.tf" ]; then
        error "❌ Arquivo main.tf não encontrado em $TERRAFORM_DIR"
        exit 1
    fi
    
    # Verificar credenciais AWS
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        error "❌ Credenciais AWS não configuradas ou inválidas"
        error "Execute: ./scripts/aws-config.sh"
        exit 1
    fi
    
    # Verificar se terraform está inicializado
    cd "$TERRAFORM_DIR"
    if [ ! -d ".terraform" ]; then
        log "🔧 Inicializando Terraform..."
        terraform init
    fi
    
    # Verificar se já existe infraestrutura
    if terraform show -json 2>/dev/null | jq -e '.values.root_module.resources | length > 0' >/dev/null 2>&1; then
        warning "⚠️  Infraestrutura já existe! Destruindo primeiro..."
        terraform destroy -auto-approve
    fi
    
    success "✅ Pré-requisitos verificados"
}

# Função para aplicar infraestrutura
apply_infrastructure() {
    log "🏗️  Aplicando infraestrutura EKS..."
    cd "$TERRAFORM_DIR"
    
    # Apply com timeout de 45 minutos
    timeout 2700 terraform apply -auto-approve 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        success "✅ Infraestrutura criada com sucesso!"
        return 0
    else
        error "❌ Falha na criação da infraestrutura"
        return 1
    fi
}

# Função para configurar kubectl
configure_kubectl() {
    log "⚙️  Configurando kubectl..."
    
    # Configurar kubeconfig
    aws eks update-kubeconfig --region us-east-1 --name "$CLUSTER_NAME" 2>&1 | tee -a "$LOG_FILE"
    
    # Verificar se cluster está acessível
    if kubectl get nodes >/dev/null 2>&1; then
        success "✅ Cluster EKS acessível via kubectl"
        kubectl get nodes | tee -a "$LOG_FILE"
        return 0
    else
        error "❌ Não foi possível acessar o cluster"
        return 1
    fi
}

# Função para deployar aplicação
deploy_application() {
    log "🚀 Fazendo deploy da aplicação..."
    
    # Deploy dos manifests
    kubectl apply -f ../../manifests/application/ 2>&1 | tee -a "$LOG_FILE"
    
    # Aguardar pods ficarem prontos (timeout 5 minutos)
    log "⏳ Aguardando pods ficarem prontos..."
    kubectl wait --for=condition=Ready pod -l app=fiap-soat-app -n fiap-soat --timeout=300s 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        success "✅ Aplicação deployada com sucesso!"
        kubectl get pods,svc -n fiap-soat | tee -a "$LOG_FILE"
        return 0
    else
        warning "⚠️  Timeout ou erro no deploy da aplicação"
        kubectl get pods,svc -n fiap-soat | tee -a "$LOG_FILE"
        return 1
    fi
}

# Função para executar testes
run_tests() {
    log "🧪 Executando testes de funcionalidade..."
    
    # Teste básico: verificar se pods estão rodando
    local pods_ready=$(kubectl get pods -n fiap-soat -o jsonpath='{.items[*].status.phase}' | grep -c "Running" || echo "0")
    
    if [ "$pods_ready" -gt 0 ]; then
        success "✅ $pods_ready pod(s) executando corretamente"
        
        # Mostrar logs da aplicação
        log "📋 Logs da aplicação:"
        kubectl logs -l app=fiap-soat-app -n fiap-soat --tail=20 | tee -a "$LOG_FILE"
        
        # Teste de conectividade (se possível)
        log "🌐 Testando conectividade interna..."
        kubectl exec -n fiap-soat deployment/fiap-soat-app -- wget -qO- http://localhost:3000/health 2>/dev/null | tee -a "$LOG_FILE" || warning "⚠️  Health check não disponível"
        
        return 0
    else
        error "❌ Nenhum pod executando corretamente"
        return 1
    fi
}

# Função principal de monitoramento
monitor_and_test() {
    local start_time=$(date +%s)
    local end_time=$((start_time + MAX_RUNTIME_MINUTES * 60))
    
    log "⏰ Iniciando monitoramento. Tempo máximo: $MAX_RUNTIME_MINUTES minutos"
    log "🛑 Destruição automática às: $(date -d @$end_time '+%Y-%m-%d %H:%M:%S')"
    
    # Loop de monitoramento
    while [ $(date +%s) -lt $end_time ]; do
        current_time=$(date +%s)
        runtime_minutes=$(((current_time - start_time) / 60))
        remaining_minutes=$(((end_time - current_time) / 60))
        
        log "⏱️  Runtime: ${runtime_minutes}m | Restante: ${remaining_minutes}m"
        
        # Verificar saúde do cluster a cada 5 minutos
        if [ $((runtime_minutes % 5)) -eq 0 ] && [ $runtime_minutes -gt 0 ]; then
            kubectl get nodes,pods -A --no-headers 2>/dev/null | wc -l >/dev/null || warning "⚠️  Cluster pode estar com problemas"
        fi
        
        # Avisos de tempo
        if [ $remaining_minutes -eq 30 ]; then
            warning "⚠️  30 minutos restantes - prepare-se para destruição automática!"
        elif [ $remaining_minutes -eq 10 ]; then
            warning "🚨 10 minutos restantes - salvando dados importantes..."
        elif [ $remaining_minutes -eq 5 ]; then
            warning "🚨 5 minutos restantes - finalizando testes..."
        fi
        
        sleep 60  # Check a cada minuto
    done
    
    warning "⏰ Tempo limite alcançado! Iniciando destruição automática..."
}

# Registrar handler para limpeza em caso de interrupção
trap cleanup EXIT INT TERM

# Início do script
echo "============================================="
echo "🧪 TESTE SEGURO EKS - AWS ACADEMY"
echo "============================================="
echo "⏱️  Tempo máximo: $MAX_RUNTIME_MINUTES minutos"
echo "💰 Custo estimado máximo: ~\$$(echo "scale=4; $MAX_RUNTIME_MINUTES * 0.11 / 60" | bc) USD"
echo "📋 Log: $LOG_FILE"
echo "============================================="
echo

runtime_minutes=0

# Execução das etapas
log "🚀 Iniciando teste seguro do EKS..."

check_prerequisites
if apply_infrastructure; then
    if configure_kubectl; then
        if deploy_application; then
            run_tests
            log "✅ Teste concluído com sucesso! Aguardando ou use Ctrl+C para finalizar..."
            monitor_and_test
        else
            warning "⚠️  Falha no deploy, mas continuando para limpeza..."
        fi
    else
        warning "⚠️  Falha na configuração kubectl, mas continuando para limpeza..."
    fi
else
    error "❌ Falha na criação da infraestrutura"
fi

log "🏁 Teste finalizado!"

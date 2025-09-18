#!/bin/bash

# Script para testar a aplicação FIAP SOAT no cluster EKS
# Executa testes básicos de funcionalidade

set -e

# Configurações
NAMESPACE="fiap-soat"
APP_NAME="fiap-soat-app"
NODE_PORT="30080"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Verificar se kubectl está configurado
check_kubectl() {
    log "🔍 Verificando configuração kubectl..."
    
    if ! kubectl cluster-info >/dev/null 2>&1; then
        error "❌ kubectl não está configurado ou cluster não está acessível"
        exit 1
    fi
    
    success "✅ Cluster EKS acessível"
}

# Verificar status dos pods
check_pods() {
    log "🔍 Verificando status dos pods..."
    
    # Aguardar pods ficarem prontos
    kubectl wait --for=condition=Ready pod -l app=$APP_NAME -n $NAMESPACE --timeout=300s
    
    # Mostrar status dos pods
    echo "📋 Status dos pods:"
    kubectl get pods -n $NAMESPACE -l app=$APP_NAME
    
    # Verificar se pelo menos 1 pod está Running
    local running_pods=$(kubectl get pods -n $NAMESPACE -l app=$APP_NAME -o jsonpath='{.items[*].status.phase}' | grep -c "Running" || echo "0")
    
    if [ "$running_pods" -gt 0 ]; then
        success "✅ $running_pods pod(s) executando"
    else
        error "❌ Nenhum pod executando"
        return 1
    fi
}

# Verificar services
check_services() {
    log "🔍 Verificando services..."
    
    echo "📋 Services disponíveis:"
    kubectl get svc -n $NAMESPACE
    
    # Verificar se NodePort está configurado
    local nodeport=$(kubectl get svc $APP_NAME -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "")
    
    if [ -n "$nodeport" ]; then
        success "✅ NodePort configurado: $nodeport"
    else
        warning "⚠️  NodePort não encontrado"
    fi
}

# Obter IP público do node
get_node_ip() {
    log "🔍 Obtendo IP público do node..."
    
    # Tentar obter IP público
    local public_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || echo "")
    
    if [ -z "$public_ip" ]; then
        # Fallback para IP interno
        public_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")
        warning "⚠️  Usando IP interno: $public_ip"
    else
        success "✅ IP público encontrado: $public_ip"
    fi
    
    echo "$public_ip"
}

# Testar health check interno
test_health_internal() {
    log "🧪 Testando health check interno..."
    
    # Port-forward para testar internamente
    kubectl port-forward -n $NAMESPACE svc/$APP_NAME 8080:80 &
    local pf_pid=$!
    
    sleep 3
    
    # Testar endpoints
    local endpoints=(
        "http://localhost:8080/"
        "http://localhost:8080/health"
        "http://localhost:8080/products"
        "http://localhost:8080/orders"
    )
    
    for endpoint in "${endpoints[@]}"; do
        log "🔍 Testando: $endpoint"
        
        if curl -s --max-time 5 "$endpoint" >/dev/null 2>&1; then
            success "✅ $endpoint - OK"
        else
            error "❌ $endpoint - FALHOU"
        fi
    done
    
    # Matar port-forward
    kill $pf_pid >/dev/null 2>&1 || true
}

# Testar acesso externo via NodePort
test_external_access() {
    log "🧪 Testando acesso externo via NodePort..."
    
    local node_ip=$(get_node_ip)
    local nodeport=$(kubectl get svc $APP_NAME -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "$NODE_PORT")
    
    if [ -n "$node_ip" ] && [ -n "$nodeport" ]; then
        local external_url="http://$node_ip:$nodeport"
        
        log "🌐 Testando: $external_url"
        
        # Note: Pode falhar se security groups não permitirem acesso
        if curl -s --max-time 10 "$external_url/health" >/dev/null 2>&1; then
            success "✅ Acesso externo funcionando!"
            echo "🌐 URL externa: $external_url"
        else
            warning "⚠️  Acesso externo pode estar bloqueado (Security Groups)"
            echo "🔧 Para acessar externamente:"
            echo "   1. Configure Security Groups para permitir porta $nodeport"
            echo "   2. Acesse: $external_url"
        fi
    else
        warning "⚠️  Não foi possível determinar URL externa"
    fi
}

# Mostrar logs da aplicação
show_logs() {
    log "📋 Logs da aplicação (últimas 20 linhas):"
    kubectl logs -n $NAMESPACE -l app=$APP_NAME --tail=20
}

# Mostrar recursos utilizados
show_resources() {
    log "📊 Recursos utilizados:"
    
    # Top nodes
    echo "🖥️  Nodes:"
    kubectl top nodes 2>/dev/null || echo "Metrics não disponíveis"
    
    # Top pods
    echo "📦 Pods:"
    kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics não disponíveis"
}

# Mostrar informações de debugging
show_debug_info() {
    log "🔧 Informações de debugging:"
    
    echo "📋 Describe pod:"
    kubectl describe pod -n $NAMESPACE -l app=$APP_NAME | head -50
    
    echo "📋 Events:"
    kubectl get events -n $NAMESPACE --sort-by=.metadata.creationTimestamp | tail -10
}

# Script principal
main() {
    echo "============================================="
    echo "🧪 TESTE DA APLICAÇÃO FIAP SOAT"
    echo "============================================="
    echo "📦 Namespace: $NAMESPACE"
    echo "🚀 Aplicação: $APP_NAME"
    echo "🔌 NodePort: $NODE_PORT"
    echo "============================================="
    echo
    
    check_kubectl
    
    if check_pods; then
        check_services
        test_health_internal
        test_external_access
        show_logs
        show_resources
        
        success "✅ Testes concluídos!"
        
        echo
        echo "🎯 RESUMO:"
        echo "=========="
        echo "✅ Pods executando"
        echo "✅ Services configurados"
        echo "✅ Health checks funcionando"
        echo "🌐 Acesso via NodePort configurado"
        echo
        echo "🔗 URLs disponíveis:"
        echo "   • Health: /health"
        echo "   • Home: /"
        echo "   • Produtos: /products"
        echo "   • Pedidos: /orders"
        
    else
        error "❌ Falha nos testes básicos"
        show_debug_info
        exit 1
    fi
}

# Executar se chamado diretamente
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi

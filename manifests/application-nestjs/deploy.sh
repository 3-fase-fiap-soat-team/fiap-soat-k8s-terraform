#!/bin/bash

# 🚀 FIAP SOAT - Deploy Script para EKS
# Este script facilita o deploy da aplicação NestJS no Kubernetes

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# Banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              🚀 FIAP SOAT EKS DEPLOY                     ║"
echo "║                   NestJS Application                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Verificar se kubectl está disponível
if ! command -v kubectl &> /dev/null; then
    error "kubectl não está instalado ou não está no PATH"
fi

# Verificar conexão com cluster
log "Verificando conexão com cluster EKS..."
if ! kubectl cluster-info &> /dev/null; then
    error "Não foi possível conectar ao cluster Kubernetes"
fi

cluster_name=$(kubectl config current-context)
success "Conectado ao cluster: $cluster_name"

# Diretório dos manifests
MANIFEST_DIR="/home/rafae/fiap-arch-software/fiap-soat-k8s-terraform/manifests/application-nestjs"

if [[ ! -d "$MANIFEST_DIR" ]]; then
    error "Diretório de manifests não encontrado: $MANIFEST_DIR"
fi

cd "$MANIFEST_DIR"

# Menu de opções
echo ""
echo "Escolha uma opção:"
echo "1) 🏗️  Deploy completo (namespace + app + services)"
echo "2) 🔄 Atualizar apenas deployment"
echo "3) 🌐 Atualizar apenas services"
echo "4) 📊 Status da aplicação"
echo "5) 🗑️  Remover aplicação"
echo "6) 🔍 Logs da aplicação"
echo "7) ⭐ Usar template de produção (NestJS real)"
echo ""

read -p "Digite sua escolha (1-7): " choice

case $choice in
    1)
        log "Iniciando deploy completo..."
        
        log "1/3 Aplicando namespace e configurações..."
        kubectl apply -f 01-namespace.yaml
        
        log "2/3 Aplicando deployment..."
        kubectl apply -f 02-deployment.yaml
        
        log "3/3 Aplicando services..."
        kubectl apply -f 03-service.yaml
        
        success "Deploy completo finalizado!"
        
        log "Aguardando pods ficarem prontos..."
        kubectl wait --for=condition=ready pod -l app=fiap-soat-nestjs -n fiap-soat-app --timeout=120s
        
        echo ""
        kubectl get all -n fiap-soat-app
        
        echo ""
        lb_url=$(kubectl get svc fiap-soat-nestjs -n fiap-soat-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        if [[ -n "$lb_url" ]]; then
            success "Aplicação disponível em: http://$lb_url"
        else
            warning "LoadBalancer ainda sendo provisionado..."
        fi
        ;;
        
    2)
        log "Atualizando deployment..."
        kubectl apply -f 02-deployment.yaml
        kubectl rollout status deployment/fiap-soat-nestjs -n fiap-soat-app
        success "Deployment atualizado!"
        ;;
        
    3)
        log "Atualizando services..."
        kubectl apply -f 03-service.yaml
        success "Services atualizados!"
        ;;
        
    4)
        log "Status da aplicação:"
        echo ""
        kubectl get all -n fiap-soat-app
        echo ""
        
        log "Health check dos pods:"
        kubectl get pods -n fiap-soat-app -o wide
        
        echo ""
        lb_url=$(kubectl get svc fiap-soat-nestjs -n fiap-soat-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        if [[ -n "$lb_url" ]]; then
            success "URL da aplicação: http://$lb_url"
            log "Testando conectividade..."
            if curl -s -I "http://$lb_url" | head -1 | grep -q "200 OK"; then
                success "Aplicação respondendo corretamente!"
            else
                warning "Aplicação pode não estar respondendo"
            fi
        fi
        ;;
        
    5)
        warning "Esta ação irá remover TODOS os recursos da aplicação!"
        read -p "Tem certeza? (y/N): " confirm
        
        if [[ $confirm == [yY] ]]; then
            log "Removendo aplicação..."
            kubectl delete -f 03-service.yaml --ignore-not-found=true
            kubectl delete -f 02-deployment.yaml --ignore-not-found=true
            kubectl delete -f 01-namespace.yaml --ignore-not-found=true
            success "Aplicação removida!"
        else
            log "Operação cancelada"
        fi
        ;;
        
    6)
        log "Obtendo logs da aplicação..."
        kubectl logs -n fiap-soat-app -l app=fiap-soat-nestjs --tail=50 -f
        ;;
        
    7)
        warning "Esta opção irá substituir os manifests atuais pelos templates de produção"
        warning "A aplicação atual (nginx) será substituída pela configuração NestJS"
        read -p "Continuar? (y/N): " confirm
        
        if [[ $confirm == [yY] ]]; then
            if [[ -f "02-deployment-production.yaml.template" ]]; then
                log "Copiando template de deployment de produção..."
                cp 02-deployment-production.yaml.template 02-deployment.yaml
                success "Deployment template copiado!"
            fi
            
            if [[ -f "03-service-production.yaml.template" ]]; then
                log "Copiando template de service de produção..."
                cp 03-service-production.yaml.template 03-service.yaml
                success "Service template copiado!"
            fi
            
            warning "IMPORTANTE: Você precisa ter a imagem 'fiap-soat/nestjs-app:latest' disponível!"
            warning "Execute o deploy novamente (opção 1) para aplicar as mudanças"
        else
            log "Operação cancelada"
        fi
        ;;
        
    *)
        error "Opção inválida!"
        ;;
esac

echo ""
log "Script finalizado!"

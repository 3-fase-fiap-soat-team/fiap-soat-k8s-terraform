#!/bin/bash

# Script de deploy para FIAP SOAT - AWS Academy
# Autor: rs94458
# Uso: ./scripts/deploy.sh
# Versão 2.0 - Com limpeza robusta e deploy automatizado

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
CLUSTER_NAME="fiap-soat-cluster"
AWS_REGION="us-east-1"

# Detectar diretório base do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_DIR/environments/dev"

MAX_RETRIES=3
CREDENTIAL_CHECK_INTERVAL=300 # 5 minutos

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

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] ✅ $1${NC}"
}

# Verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    command -v terraform >/dev/null 2>&1 || error "Terraform não encontrado. Instale: https://terraform.io/"
    command -v kubectl >/dev/null 2>&1 || error "kubectl não encontrado. Instale: https://kubernetes.io/docs/tasks/tools/"
    command -v aws >/dev/null 2>&1 || error "AWS CLI não encontrado. Instale: https://aws.amazon.com/cli/"
    
    success "Dependências verificadas"
}

# Verificar e renovar credenciais AWS
check_aws_credentials() {
    log "Verificando credenciais AWS..."
    
    local retry_count=0
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if aws sts get-caller-identity >/dev/null 2>&1; then
            ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
            USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
            
            # Verificar se são credenciais temporárias (AWS Academy)
            if echo "$USER_ARN" | grep -q "assumed-role"; then
                info "Credenciais temporárias detectadas (AWS Academy)"
                
                # Verificar tempo restante (aproximado)
                local session_token=$(aws configure get aws_session_token)
                if [ -n "$session_token" ]; then
                    warn "⏰ Lembre-se: credenciais AWS Academy expiram em ~3h"
                fi
            fi
            
            success "Conectado à conta AWS: $ACCOUNT_ID"
            return 0
        else
            retry_count=$((retry_count + 1))
            warn "Falha na verificação de credenciais (tentativa $retry_count/$MAX_RETRIES)"
            
            if [ $retry_count -lt $MAX_RETRIES ]; then
                info "💡 Configure novas credenciais com: ./scripts/aws-config.sh"
                read -p "Pressione Enter após configurar as credenciais ou Ctrl+C para cancelar..."
            fi
        fi
    done
    
    error "Credenciais AWS inválidas após $MAX_RETRIES tentativas"
}

# Verificar se credenciais ainda estão válidas
verify_credentials() {
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        warn "🔄 Credenciais expiraram durante a operação"
        info "💡 Renove as credenciais com: ./scripts/aws-config.sh"
        read -p "Pressione Enter após renovar as credenciais..."
        check_aws_credentials
    fi
}

# Limpar state órfão e inconsistente
clean_terraform_state() {
    log "🧹 Limpando estado do Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Verificar se há state file
    if [ ! -f "terraform.tfstate" ]; then
        info "Nenhum state file encontrado - deploy limpo"
        check_orphaned_resources_before_deploy
    else
        # Verificar consistência do state com AWS
        check_state_consistency
    fi
    
    # Limpar planos e backups órfãos
    rm -f tfplan terraform.tfstate.backup.drift-* 2>/dev/null || true
    
    success "State limpo"
    cd - >/dev/null
}

# Verificar recursos órfãos antes do deploy
check_orphaned_resources_before_deploy() {
    log "🔍 Verificando recursos órfãos antes do deploy..."
    
    # Verificar VPCs órfãs do projeto
    local vpc_ids=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Project,Values=fiap-soat*" \
        --query 'Vpcs[].VpcId' \
        --output text 2>/dev/null || true)
    
    if [ -n "$vpc_ids" ] && [ "$vpc_ids" != "None" ]; then
        warn "🚨 Detectadas VPCs órfãs do projeto: $vpc_ids"
        echo
        echo "Opções disponíveis:"
        echo "1) 🗑️  Remover VPCs órfãs (recomendado para deploy limpo)"
        echo "2) 🔄 Tentar reutilizar VPCs existentes (arriscado)"
        echo "3) ⏭️  Continuar e deixar o Terraform decidir"
        echo
        read -p "Escolha (1-3): " vpc_choice
        
        case $vpc_choice in
            1)
                log "Removendo VPCs órfãs antes do deploy..."
                for vpc_id in $vpc_ids; do
                    cleanup_single_vpc "$vpc_id"
                done
                ;;
            2)
                warn "⚠️  ARRISCADO: Terraform pode dar conflito ou erro"
                warn "💡 Monitore o plano do Terraform cuidadosamente"
                ;;
            3)
                info "Continuando com deploy - Terraform tentará resolver conflitos"
                warn "⚠️  Se houver erro, execute limpeza de órfãos (opção 8 do menu)"
                ;;
            *)
                error "Opção inválida"
                ;;
        esac
    fi
    
    # Verificar outros recursos órfãos
    local clusters=$(aws eks list-clusters --query "clusters[?contains(@, \`$CLUSTER_NAME\`)]" --output text 2>/dev/null || true)
    if [ -n "$clusters" ] && [ "$clusters" != "None" ]; then
        warn "🚨 Cluster EKS órfão detectado: $clusters"
        warn "⚠️  Terraform pode dar erro ao tentar criar cluster com mesmo nome"
        echo
        read -p "Remover cluster órfão antes do deploy? (s/N): " remove_cluster
        
        if [[ "$remove_cluster" =~ ^[Ss]$ ]]; then
            aws eks delete-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" || true
            log "Aguardando remoção do cluster..."
            sleep 60
        fi
    fi
}

# Verificar consistência do state com AWS  
check_state_consistency() {
    log "🔍 Verificando consistência do state com AWS..."
    
    # Verificar se recursos no state ainda existem no AWS
    local resources=$(terraform state list 2>/dev/null || true)
    
    if [ -n "$resources" ]; then
        echo "$resources" | while read resource; do
            case $resource in
                *aws_eks_cluster*)
                    local cluster_name_state=$(terraform state show "$resource" 2>/dev/null | grep "name.*=" | awk '{print $3}' | tr -d '"' || true)
                    if [ -n "$cluster_name_state" ]; then
                        if ! aws eks describe-cluster --name "$cluster_name_state" --region "$AWS_REGION" >/dev/null 2>&1; then
                            warn "Cluster '$cluster_name_state' no state mas não existe no AWS"
                            warn "Removendo do state: $resource"
                            terraform state rm "$resource" || true
                        fi
                    fi
                    ;;
                *aws_vpc*)
                    local vpc_id_state=$(terraform state show "$resource" 2>/dev/null | grep "id.*=" | awk '{print $3}' | tr -d '"' || true)
                    if [ -n "$vpc_id_state" ]; then
                        if ! aws ec2 describe-vpcs --vpc-ids "$vpc_id_state" >/dev/null 2>&1; then
                            warn "VPC '$vpc_id_state' no state mas não existe no AWS"
                            warn "Removendo do state: $resource"
                            terraform state rm "$resource" || true
                        fi
                    fi
                    ;;
            esac
        done
    fi
}

# Deploy robusto da infraestrutura
deploy_infrastructure() {
    log "🚀 Iniciando deploy da infraestrutura..."
    
    cd "$TERRAFORM_DIR"
    
    # Verificar credenciais antes de começar
    verify_credentials
    
    # Limpar state inconsistente
    clean_terraform_state
    
    # Inicializar Terraform
    log "Inicializando Terraform..."
    terraform init
    
    # Validar configuração
    log "Validando configuração..."
    terraform validate
    
    # Mostrar plano e detectar conflitos
    log "Criando plano de execução..."
    if ! terraform plan -out=tfplan; then
        error "❌ Falha no plano do Terraform!"
        warn "💡 Possíveis causas:"
        warn "   • Recursos órfãos conflitando"
        warn "   • CIDR blocks duplicados" 
        warn "   • Tags conflitantes"
        warn "   • Nomes de recursos já existentes"
        echo
        warn "🔧 Soluções:"
        warn "   1) Execute: ./scripts/deploy.sh (opção 8 - Limpar órfãos)"
        warn "   2) Execute: ./scripts/deploy.sh (opção 9 - Limpar state)"
        warn "   3) Verifique manualmente no console AWS"
        exit 1
    fi
    
    # Verificar se o plano indica recursos órfãos sendo importados/conflitados
    log "Analisando plano para detectar conflitos reais..."
    if terraform show tfplan | grep -q "will be imported\|already exists" | grep -v "resolve_conflicts"; then
        warn "⚠️  Detectados possíveis conflitos no plano:"
        terraform show tfplan | grep -A 2 -B 2 "will be imported\|already exists" | grep -v "resolve_conflicts" || true
        echo
        read -p "Continuar mesmo assim? (s/N): " continue_with_conflicts
        
        if [[ ! "$continue_with_conflicts" =~ ^[Ss]$ ]]; then
            error "Deploy cancelado devido a conflitos detectados"
        fi
    else
        info "Plano validado - nenhum conflito real detectado"
    fi
    
    # Confirmar aplicação
    warn "⚠️  ATENÇÃO: Este deploy criará recursos que CUSTAM DINHEIRO na AWS!"
    warn "💰 EKS Control Plane: ~$73/mês"
    warn "💰 Node Group (t3.small): ~$15/mês"
    warn "💰 Total estimado: ~$88/mês (pode estourar budget AWS Academy!)"
    echo
    read -p "Deseja continuar? (digite 'sim' para confirmar): " confirm
    
    if [ "$confirm" != "sim" ]; then
        error "Deploy cancelado pelo usuário"
    fi
    
    # Aplicar mudanças com retry em caso de expiração de credenciais
    local apply_success=false
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ] && [ "$apply_success" = false ]; do
        log "Aplicando mudanças (tentativa $((retry_count + 1))/$MAX_RETRIES)..."
        
        if terraform apply tfplan; then
            apply_success=true
            success "Infraestrutura criada com sucesso!"
        else
            retry_count=$((retry_count + 1))
            
            if [ $retry_count -lt $MAX_RETRIES ]; then
                warn "Falha no apply. Verificando se foi problema de credenciais..."
                verify_credentials
                
                # Recriar plano com credenciais renovadas
                log "Recriando plano com credenciais renovadas..."
                terraform plan -out=tfplan
            fi
        fi
    done
    
    if [ "$apply_success" = false ]; then
        error "Falha no deploy após $MAX_RETRIES tentativas"
    fi
    
    # Aguardar cluster ficar ativo
    wait_for_cluster_ready
    
    cd - >/dev/null
}

# Aguardar cluster ficar pronto
wait_for_cluster_ready() {
    log "⏳ Aguardando cluster ficar ACTIVE..."
    
    local max_wait=900  # 15 minutos
    local wait_time=0
    local check_interval=30
    
    while [ $wait_time -lt $max_wait ]; do
        verify_credentials  # Verificar credenciais a cada check
        
        local status=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'cluster.status' --output text 2>/dev/null || echo "NOT_FOUND")
        
        if [ "$status" = "ACTIVE" ]; then
            success "Cluster está ACTIVE!"
            return 0
        elif [ "$status" = "FAILED" ] || [ "$status" = "NOT_FOUND" ]; then
            error "Cluster falhou ou não foi encontrado. Status: $status"
        else
            info "Status do cluster: $status (aguardando...)"
            sleep $check_interval
            wait_time=$((wait_time + check_interval))
        fi
    done
    
    error "Timeout aguardando cluster ficar ativo (${max_wait}s)"
}

# Remover aplicação Kubernetes
cleanup_application() {
    log "🧹 Removendo aplicação do Kubernetes..."
    
    if kubectl get namespace fiap-soat >/dev/null 2>&1; then
        kubectl delete -f manifests/application/ --ignore-not-found=true || true
        kubectl delete -f manifests/application-nestjs/ --ignore-not-found=true || true
        kubectl delete namespace fiap-soat --ignore-not-found=true || true
        success "Aplicação removida"
    else
        info "Namespace 'fiap-soat' não encontrado"
    fi
}

# Verificar recursos AWS restantes
check_aws_resources() {
    log "📊 Verificando recursos AWS restantes..."
    
    verify_credentials
    
    echo
    echo -e "${BLUE}=== 🏗️  EKS CLUSTERS ===${NC}"
    aws eks list-clusters --query "clusters[?contains(@, \`$CLUSTER_NAME\`)]" --output table 2>/dev/null || echo "Nenhum cluster encontrado"
    
    echo
    echo -e "${BLUE}=== 🖥️  EC2 INSTANCES ===${NC}"
    aws ec2 describe-instances \
        --filters "Name=tag:Project,Values=fiap-soat*" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType,Name:Tags[?Key==`Name`]|[0].Value}' \
        --output table 2>/dev/null || echo "Nenhuma instância encontrada"
    
    echo
    echo -e "${BLUE}=== ⚖️  LOAD BALANCERS ===${NC}"
    aws elbv2 describe-load-balancers \
        --query "LoadBalancers[?contains(LoadBalancerName, \`fiap-soat\`)].{Name:LoadBalancerName,State:State.Code,Type:Type}" \
        --output table 2>/dev/null || echo "Nenhum load balancer encontrado"
    
    echo
    echo -e "${BLUE}=== 🌐 VPCs ===${NC}"
    aws ec2 describe-vpcs \
        --filters "Name=tag:Project,Values=fiap-soat*" \
        --query 'Vpcs[].{ID:VpcId,CIDR:CidrBlock,State:State,Name:Tags[?Key==`Name`]|[0].Value}' \
        --output table 2>/dev/null || echo "Nenhuma VPC encontrada"
    
    echo
    echo -e "${BLUE}=== 💾 VOLUMES EBS ===${NC}"
    aws ec2 describe-volumes \
        --filters "Name=tag:Project,Values=fiap-soat*" \
        --query 'Volumes[].{ID:VolumeId,Size:Size,State:State,Type:VolumeType}' \
        --output table 2>/dev/null || echo "Nenhum volume encontrado"
}

# Limpeza completa de recursos
cleanup_resources() {
    log "🧹 Iniciando limpeza completa de recursos..."
    
    # Mostrar recursos antes da destruição
    info "Verificando recursos que serão destruídos..."
    check_aws_resources
    
    echo
    # Confirmar limpeza
    warn "⚠️  ATENÇÃO: Isso irá DESTRUIR TODOS os recursos AWS criados!"
    warn "💀 Cluster EKS, Node Groups, VPC, Load Balancers, etc."
    warn "💰 Isso irá PARAR TODOS OS CUSTOS AWS!"
    warn "🔥 Esta ação é IRREVERSÍVEL!"
    echo
    read -p "Tem certeza? Digite 'DESTRUIR' para confirmar: " confirm
    
    if [ "$confirm" != "DESTRUIR" ]; then
        info "Limpeza cancelada pelo usuário"
        warn "💰 Lembre-se: recursos AWS continuam gerando custos!"
        return 0
    fi
    
    # Remover aplicação primeiro
    cleanup_application
    
    cd "$TERRAFORM_DIR"
    verify_credentials
    
    # Mostrar plano de destroy
    log "Criando plano de destruição..."
    terraform plan -destroy -out=tfplan-destroy
    
    # Tentar destroy normal primeiro
    log "Executando destruição..."
    if terraform apply tfplan-destroy; then
        success "Destroy executado com sucesso!"
    else
        warn "Destroy falhou. Tentando limpeza forçada..."
        force_cleanup
    fi
    
    # Limpar contexto kubectl
    cleanup_kubectl_context
    
    # Limpar state e arquivos temporários
    cleanup_local_files
    
    # Verificar se restaram recursos órfãos
    log "Verificando recursos órfãos..."
    check_aws_resources
    
    success "🎉 Limpeza completa finalizada!"
    success "💰 Recursos AWS removidos - custos parados!"
    cd - >/dev/null
}

# Limpar contexto kubectl
cleanup_kubectl_context() {
    log "🧹 Limpando contexto kubectl..."
    
    if command -v kubectl >/dev/null 2>&1; then
        local current_context=$(kubectl config current-context 2>/dev/null || echo "")
        if [[ "$current_context" == *"fiap-soat"* ]]; then
            kubectl config delete-context "$current_context" 2>/dev/null || true
            kubectl config delete-cluster "$CLUSTER_NAME" 2>/dev/null || true
            success "Contexto kubectl removido"
        fi
    fi
}

# Limpar arquivos locais
cleanup_local_files() {
    log "🧹 Limpando arquivos temporários..."
    
    # Remover arquivos terraform
    rm -f terraform.tfstate* tfplan* .terraform.lock.hcl 2>/dev/null || true
    rm -rf .terraform/ 2>/dev/null || true
    
    # Remover backups antigos
    find . -name "terraform.tfstate.backup*" -delete 2>/dev/null || true
    find . -name "tfplan*" -delete 2>/dev/null || true
    
    success "Arquivos temporários limpos"
}

# Limpeza forçada para casos extremos
force_cleanup() {
    warn "⚠️  Executando limpeza forçada de recursos órfãos..."
    
    # Confirmar limpeza forçada
    echo
    warn "🔥 LIMPEZA FORÇADA: Tentativa de remover recursos órfãos individualmente"
    warn "⚠️  Isso pode deixar alguns recursos órfãos que custam dinheiro!"
    read -p "Continuar com limpeza forçada? (s/N): " force_confirm
    
    if [[ ! "$force_confirm" =~ ^[Ss]$ ]]; then
        info "Limpeza forçada cancelada"
        return 0
    fi
    
    # Listar recursos que ainda existem
    local resources=$(terraform state list 2>/dev/null || true)
    
    if [ -n "$resources" ]; then
        log "Removendo recursos individualmente..."
        
        # Remover node groups primeiro (dependências críticas)
        echo "$resources" | grep "aws_eks_node_group" | while read resource; do
            log "Removendo node group: $resource"
            terraform destroy -target="$resource" -auto-approve || true
            sleep 10
        done
        
        # Remover addons EKS
        echo "$resources" | grep "aws_eks_addon" | while read resource; do
            log "Removendo addon: $resource"
            terraform destroy -target="$resource" -auto-approve || true
            sleep 5
        done
        
        # Aguardar node groups serem removidos
        log "Aguardando remoção de node groups..."
        sleep 30
        
        # Remover cluster
        echo "$resources" | grep "aws_eks_cluster" | while read resource; do
            log "Removendo cluster: $resource"
            terraform destroy -target="$resource" -auto-approve || true
            sleep 10
        done
        
        # Aguardar cluster ser removido
        log "Aguardando remoção do cluster..."
        sleep 60
        
        # Tentar destroy completo final
        log "Tentando destroy completo final..."
        terraform destroy -auto-approve || warn "Alguns recursos podem não ter sido removidos"
    fi
    
    # Limpeza manual de recursos órfãos
    cleanup_orphaned_resources
    
    # Verificar recursos restantes
    log "Verificando recursos restantes..."
    check_aws_resources
    
    warn "🚨 IMPORTANTE: Verifique manualmente no console AWS se há recursos órfãos:"
    warn "   • EC2 → Instâncias"
    warn "   • EKS → Clusters"  
    warn "   • VPC → Suas VPCs"
    warn "   • EC2 → Load Balancers"
    warn "💰 Recursos órfãos podem continuar gerando custos!"
}

# Limpeza de recursos órfãos via AWS CLI
cleanup_orphaned_resources() {
    log "🔍 Verificando recursos órfãos via AWS CLI..."
    
    verify_credentials
    
    # Verificar e remover node groups órfãos primeiro
    log "Verificando node groups..."
    local node_groups=$(aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'nodegroups[]' --output text 2>/dev/null || true)
    
    if [ -n "$node_groups" ] && [ "$node_groups" != "None" ]; then
        warn "🚨 Node groups órfãos detectados: $node_groups"
        for ng in $node_groups; do
            log "Removendo node group: $ng"
            aws eks delete-nodegroup \
                --cluster-name "$CLUSTER_NAME" \
                --nodegroup-name "$ng" \
                --region "$AWS_REGION" 2>/dev/null || true
        done
        
        # Aguardar remoção dos node groups
        log "Aguardando remoção dos node groups..."
        sleep 60
    fi
    
    # Verificar e remover addons órfãos
    log "Verificando addons EKS..."
    local addons=$(aws eks list-addons --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'addons[]' --output text 2>/dev/null || true)
    
    if [ -n "$addons" ] && [ "$addons" != "None" ]; then
        warn "🚨 Addons órfãos detectados: $addons"
        for addon in $addons; do
            log "Removendo addon: $addon"
            aws eks delete-addon \
                --cluster-name "$CLUSTER_NAME" \
                --addon-name "$addon" \
                --region "$AWS_REGION" 2>/dev/null || true
        done
    fi
    
    # Verificar e remover cluster órfão
    log "Verificando cluster EKS..."
    if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
        warn "🚨 Cluster órfão detectado: $CLUSTER_NAME"
        log "Removendo cluster..."
        aws eks delete-cluster \
            --name "$CLUSTER_NAME" \
            --region "$AWS_REGION" 2>/dev/null || true
        
        # Aguardar remoção do cluster
        log "Aguardando remoção do cluster..."
        sleep 90
    fi
    
    # Verificar instâncias EC2 órfãs do projeto
    log "Verificando instâncias EC2..."
    local instances=$(aws ec2 describe-instances \
        --filters "Name=tag:Project,Values=fiap-soat*" "Name=instance-state-name,Values=running,pending" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text 2>/dev/null || true)
    
    if [ -n "$instances" ] && [ "$instances" != "None" ]; then
        warn "🚨 Instâncias EC2 órfãs detectadas: $instances"
        warn "⚠️  Considere remover manualmente no console AWS"
    fi
    
    # Verificar e limpar VPCs órfãs
    cleanup_orphaned_vpcs
    
    success "✅ Verificação de recursos órfãos concluída"
}

# Limpeza específica de VPCs órfãs
cleanup_orphaned_vpcs() {
    log "🔍 Verificando VPCs órfãs do projeto..."
    
    # Buscar VPCs do projeto
    local vpc_ids=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Project,Values=fiap-soat*" \
        --query 'Vpcs[].VpcId' \
        --output text 2>/dev/null || true)
    
    if [ -z "$vpc_ids" ] || [ "$vpc_ids" = "None" ]; then
        info "Nenhuma VPC órfã do projeto encontrada"
        return 0
    fi
    
    warn "🚨 VPCs órfãs detectadas: $vpc_ids"
    echo
    read -p "Deseja remover as VPCs órfãs? (s/N): " vpc_confirm
    
    if [[ ! "$vpc_confirm" =~ ^[Ss]$ ]]; then
        info "Limpeza de VPCs cancelada"
        return 0
    fi
    
    for vpc_id in $vpc_ids; do
        log "🧹 Limpando VPC: $vpc_id"
        cleanup_single_vpc "$vpc_id"
    done
}

# Limpar uma VPC específica e suas dependências
cleanup_single_vpc() {
    local vpc_id="$1"
    
    if [ -z "$vpc_id" ]; then
        error "VPC ID não fornecido"
    fi
    
    log "Removendo dependências da VPC $vpc_id..."
    
    # 1. Remover instâncias EC2 (se houver)
    log "Verificando instâncias EC2 na VPC..."
    local instances=$(aws ec2 describe-instances \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=instance-state-name,Values=running,pending,stopping,stopped" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text 2>/dev/null || true)
    
    if [ -n "$instances" ] && [ "$instances" != "None" ]; then
        warn "Terminando instâncias: $instances"
        aws ec2 terminate-instances --instance-ids $instances 2>/dev/null || true
        
        # Aguardar terminação
        log "Aguardando terminação das instâncias..."
        aws ec2 wait instance-terminated --instance-ids $instances 2>/dev/null || true
    fi
    
    # 2. Remover NAT Gateways
    log "Removendo NAT Gateways..."
    local nat_gateways=$(aws ec2 describe-nat-gateways \
        --filter "Name=vpc-id,Values=$vpc_id" \
        --query 'NatGateways[?State==`available`].NatGatewayId' \
        --output text 2>/dev/null || true)
    
    if [ -n "$nat_gateways" ] && [ "$nat_gateways" != "None" ]; then
        for nat_id in $nat_gateways; do
            log "Removendo NAT Gateway: $nat_id"
            aws ec2 delete-nat-gateway --nat-gateway-id "$nat_id" 2>/dev/null || true
        done
        
        # Aguardar NAT Gateways serem removidos
        log "Aguardando remoção dos NAT Gateways..."
        sleep 30
    fi
    
    # 3. Remover Internet Gateway
    log "Removendo Internet Gateway..."
    local igw_id=$(aws ec2 describe-internet-gateways \
        --filters "Name=attachment.vpc-id,Values=$vpc_id" \
        --query 'InternetGateways[].InternetGatewayId' \
        --output text 2>/dev/null || true)
    
    if [ -n "$igw_id" ] && [ "$igw_id" != "None" ]; then
        log "Detaching e removendo Internet Gateway: $igw_id"
        aws ec2 detach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$vpc_id" 2>/dev/null || true
        sleep 5
        aws ec2 delete-internet-gateway --internet-gateway-id "$igw_id" 2>/dev/null || true
    fi
    
    # 4. Remover Route Tables (não default e não associadas)
    log "Removendo Route Tables..."
    local route_tables=$(aws ec2 describe-route-tables \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
        --output text 2>/dev/null || true)
    
    if [ -n "$route_tables" ] && [ "$route_tables" != "None" ]; then
        for rt_id in $route_tables; do
            log "Limpando rotas da Route Table: $rt_id"
            
            # Primeiro, remover rotas customizadas (não locais)
            local routes=$(aws ec2 describe-route-tables \
                --route-table-ids "$rt_id" \
                --query 'RouteTables[0].Routes[?GatewayId!=`local`].DestinationCidrBlock' \
                --output text 2>/dev/null || true)
                
            if [ -n "$routes" ] && [ "$routes" != "None" ]; then
                for cidr in $routes; do
                    log "Removendo rota $cidr da Route Table $rt_id"
                    aws ec2 delete-route --route-table-id "$rt_id" --destination-cidr-block "$cidr" 2>/dev/null || true
                done
            fi
            
            # Aguardar um pouco
            sleep 2
            
            log "Removendo Route Table: $rt_id"
            aws ec2 delete-route-table --route-table-id "$rt_id" 2>/dev/null || true
        done
    fi
    
    # 5. Remover Security Groups (não default)
    log "Removendo Security Groups..."
    local security_groups=$(aws ec2 describe-security-groups \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
        --output text 2>/dev/null || true)
    
    if [ -n "$security_groups" ] && [ "$security_groups" != "None" ]; then
        for sg_id in $security_groups; do
            log "Removendo Security Group: $sg_id"
            aws ec2 delete-security-group --group-id "$sg_id" 2>/dev/null || true
        done
    fi
    
    # 6. Remover Subnets
    log "Removendo Subnets..."
    local subnets=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" \
        --query 'Subnets[].SubnetId' \
        --output text 2>/dev/null || true)
    
    if [ -n "$subnets" ] && [ "$subnets" != "None" ]; then
        for subnet_id in $subnets; do
            log "Removendo Subnet: $subnet_id"
            aws ec2 delete-subnet --subnet-id "$subnet_id" 2>/dev/null || true
        done
    fi
    
    # 7. Finalmente, remover a VPC
    log "Removendo VPC: $vpc_id"
    if aws ec2 delete-vpc --vpc-id "$vpc_id" 2>/dev/null; then
        success "✅ VPC $vpc_id removida com sucesso"
    else
        warn "❌ Falha ao remover VPC $vpc_id - pode ter dependências restantes"
        warn "💡 Verifique manualmente no console AWS"
    fi
}

# Configurar kubectl
configure_kubectl() {
    log "Configurando kubectl..."
    
    verify_credentials
    
    # Tentar obter informações do cluster via terraform
    local cluster_name_tf=""
    local aws_region_tf=""
    
    cd "$TERRAFORM_DIR"
    if terraform output cluster_name >/dev/null 2>&1; then
        cluster_name_tf=$(terraform output -raw cluster_name 2>/dev/null || echo "")
        aws_region_tf=$(terraform output -raw aws_region 2>/dev/null || echo "$AWS_REGION")
    fi
    cd - >/dev/null
    
    # Usar valores do terraform ou padrão
    local cluster_to_use="${cluster_name_tf:-$CLUSTER_NAME}"
    local region_to_use="${aws_region_tf:-$AWS_REGION}"
    
    # Verificar se cluster existe
    if ! aws eks describe-cluster --name "$cluster_to_use" --region "$region_to_use" >/dev/null 2>&1; then
        error "Cluster $cluster_to_use não encontrado na região $region_to_use"
    fi
    
    aws eks update-kubeconfig --region "$region_to_use" --name "$cluster_to_use"
    
    success "kubectl configurado para cluster: $cluster_to_use"
    
    # Verificar conexão
    log "Verificando conexão com cluster..."
    kubectl get nodes || warn "Falha ao conectar com o cluster"
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
    log "📊 Verificando status completo do ambiente..."
    
    verify_credentials
    
    echo
    echo -e "${BLUE}=== 🏗️  INFRAESTRUTURA AWS ===${NC}"
    
    # Status do cluster EKS
    local cluster_status=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'cluster.status' --output text 2>/dev/null || echo "NOT_FOUND")
    if [ "$cluster_status" != "NOT_FOUND" ]; then
        echo "✅ Cluster EKS: $cluster_status"
        
        # Informações do cluster
        local cluster_info=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'cluster.{Version:version,Endpoint:endpoint,CreatedAt:createdAt}' --output table 2>/dev/null || true)
        echo "$cluster_info"
        
        # Node groups
        echo
        echo "Node Groups:"
        aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION" --output table 2>/dev/null || echo "  Nenhum node group encontrado"
        
    else
        echo "❌ Cluster EKS: NÃO ENCONTRADO"
    fi
    
    echo
    echo -e "${BLUE}=== ☸️  KUBERNETES CLUSTER ===${NC}"
    
    if kubectl cluster-info >/dev/null 2>&1; then
        echo "✅ Conectividade kubectl: OK"
        
        echo
        echo "=== NODES ==="
        kubectl get nodes -o wide 2>/dev/null || echo "❌ Erro ao obter nodes"
        
        echo
        echo "=== SYSTEM PODS ==="
        kubectl get pods -n kube-system -o wide 2>/dev/null || echo "❌ Erro ao obter pods do sistema"
        
        echo
        echo "=== ALL NAMESPACES ==="
        kubectl get pods -A 2>/dev/null || echo "❌ Erro ao obter todos os pods"
        
        echo
        echo "=== SERVICES ==="
        kubectl get svc -A 2>/dev/null || echo "❌ Erro ao obter serviços"
        
        # Verificar se aplicação está deployada
        if kubectl get namespace fiap-soat >/dev/null 2>&1; then
            echo
            echo -e "${BLUE}=== 📦 FIAP SOAT APP ===${NC}"
            kubectl get all -n fiap-soat 2>/dev/null || echo "❌ Erro ao obter recursos da aplicação"
            
            echo
            echo -e "${BLUE}=== 🌐 ACCESS INFO ===${NC}"
            local node_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null)
            if [ -z "$node_ip" ]; then
                node_ip=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
            fi
            
            if [ -n "$node_ip" ]; then
                echo "Aplicação disponível em:"
                echo "  🔗 NodePort: http://$node_ip:30080"
                echo "  🔗 Port-forward: kubectl port-forward svc/fiap-soat-app 3000:80 -n fiap-soat"
            fi
        else
            warn "Namespace 'fiap-soat' não encontrado. Aplicação não deployada?"
        fi
        
    else
        echo "❌ Conectividade kubectl: FALHOU"
        warn "Configure kubectl com: $0 (opção 5)"
    fi
    
    echo
    echo -e "${BLUE}=== 💰 CUSTO ESTIMADO ===${NC}"
    echo "📊 Recursos ativos que geram custo:"
    echo "   • EKS Control Plane: ~$0.10/hora (~$73/mês)"
    echo "   • Node Group (t3.small): ~$0.0208/hora (~$15/mês)"
    echo "   • EBS Storage: ~$0.10/GB/mês"
    echo "   • Data Transfer: variável"
    echo
    warn "💡 Para evitar custos, execute limpeza completa quando não precisar do ambiente"
    
    success "Verificação de status concluída!"
}

# Menu principal
main() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "🎯 FIAP SOAT - EKS Deploy Script v2.0"
    echo "🏫 AWS Academy Optimized"
    echo "💡 Autor: rs94458"
    echo "🔧 Recursos: Deploy robusto + Limpeza completa"
    echo "=================================================="
    echo -e "${NC}"
    
    check_dependencies
    check_aws_credentials
    
    echo
    echo "Escolha uma opção:"
    echo "1) 🚀 Deploy completo (infraestrutura + aplicação)"
    echo "2) 🏗️  Apenas infraestrutura"
    echo "3) 📦 Apenas aplicação"
    echo "4) 📊 Verificar status"
    echo "5) ⚙️  Configurar kubectl"
    echo "6) 🔍 Verificar recursos AWS"
    echo "7) 🧹 Limpeza completa (DESTROY ALL)"
    echo "8) �️  Limpar recursos órfãos"
    echo "9) �🔧 Limpeza apenas do state"
    echo "0) 👋 Sair"
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
            configure_kubectl
            deploy_application
            check_status
            ;;
        4)
            configure_kubectl
            check_status
            ;;
        5)
            configure_kubectl
            ;;
        6)
            check_aws_resources
            ;;
        7)
            cleanup_resources
            ;;
        8)
            cleanup_orphaned_resources
            ;;
        9)
            clean_terraform_state
            ;;
        0)
            success "👋 Tchau!"
            exit 0
            ;;
        *)
            error "Opção inválida"
            ;;
    esac
}

# Executar script
main

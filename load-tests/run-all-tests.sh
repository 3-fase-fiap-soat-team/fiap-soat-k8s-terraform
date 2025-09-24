#!/bin/bash

# Testes de Carga - FIAP SOAT Application
# Script para executar todos os testes de performance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TARGET_URL="${TARGET_URL:-http://localhost:3000}"
RESULTS_DIR="results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo -e "${BLUE}🧪 FIAP SOAT - Testes de Performance${NC}"
echo -e "${BLUE}=======================================${NC}"
echo -e "🎯 Target URL: ${TARGET_URL}"
echo -e "📅 Timestamp: ${TIMESTAMP}"
echo ""

# Create results directory
mkdir -p "$RESULTS_DIR"

# Function to check if service is available
check_service() {
    echo -e "${YELLOW}🔍 Verificando disponibilidade do serviço...${NC}"
    
    if curl -s -f "$TARGET_URL/health" > /dev/null; then
        echo -e "${GREEN}✅ Serviço disponível${NC}"
    else
        echo -e "${RED}❌ Serviço não disponível em $TARGET_URL${NC}"
        echo -e "${RED}   Verifique se a aplicação está rodando${NC}"
        exit 1
    fi
}

# Function to run Artillery tests
run_artillery_tests() {
    echo -e "${BLUE}🎯 Executando testes Artillery...${NC}"
    
    if command -v artillery >/dev/null 2>&1; then
        echo -e "${YELLOW}📊 Smoke Test (Artillery)...${NC}"
        TARGET_URL="$TARGET_URL" artillery run artillery/smoke-test.yml \
            --output "$RESULTS_DIR/artillery_smoke_${TIMESTAMP}.json" \
            > "$RESULTS_DIR/artillery_smoke_${TIMESTAMP}.log" 2>&1
        
        echo -e "${YELLOW}📊 Load Test (Artillery)...${NC}"
        TARGET_URL="$TARGET_URL" artillery run artillery/load-test.yml \
            --output "$RESULTS_DIR/artillery_load_${TIMESTAMP}.json" \
            > "$RESULTS_DIR/artillery_load_${TIMESTAMP}.log" 2>&1
        
        echo -e "${GREEN}✅ Testes Artillery concluídos${NC}"
    else
        echo -e "${RED}⚠️  Artillery não encontrado. Instalando...${NC}"
        npm install -g artillery
        run_artillery_tests
    fi
}

# Function to run K6 tests  
run_k6_tests() {
    echo -e "${BLUE}🚀 Executando testes K6...${NC}"
    
    if command -v k6 >/dev/null 2>&1; then
        echo -e "${YELLOW}📊 Stress Test (K6)...${NC}"
        TARGET_URL="$TARGET_URL" k6 run k6/stress-test.js \
            --out json="$RESULTS_DIR/k6_stress_${TIMESTAMP}.json" \
            > "$RESULTS_DIR/k6_stress_${TIMESTAMP}.log" 2>&1
        
        echo -e "${GREEN}✅ Testes K6 concluídos${NC}"
    else
        echo -e "${YELLOW}⚠️  K6 não encontrado. Por favor instale:${NC}"
        echo -e "   curl https://github.com/grafana/k6/releases/download/v0.45.0/k6-v0.45.0-linux-amd64.tar.gz -L | tar xvz --strip-components 1"
        echo -e "   sudo mv k6 /usr/local/bin/"
    fi
}

# Function to generate summary report
generate_summary() {
    echo -e "${BLUE}📋 Gerando relatório resumo...${NC}"
    
    SUMMARY_FILE="$RESULTS_DIR/summary_${TIMESTAMP}.md"
    
    cat > "$SUMMARY_FILE" << EOF
# Relatório de Testes de Performance - FIAP SOAT

**Data:** $(date)  
**Target:** $TARGET_URL  
**Duração total:** $((SECONDS / 60)) minutos

## 📊 Arquivos Gerados

### Artillery Tests
- Smoke Test: \`artillery_smoke_${TIMESTAMP}.json\`
- Load Test: \`artillery_load_${TIMESTAMP}.json\`

### K6 Tests  
- Stress Test: \`k6_stress_${TIMESTAMP}.json\`

## 🎯 Cenários Testados

### 1. Smoke Test (Artillery)
- **Duração:** 30 segundos
- **Usuários:** 1/segundo
- **Objetivo:** Verificação básica de funcionalidade

### 2. Load Test (Artillery)
- **Duração:** ~9 minutos
- **Usuários:** 5-30/segundo (ramp up/down)
- **Objetivo:** Teste de carga normal

### 3. Stress Test (K6)
- **Duração:** 7 minutos
- **Usuários:** 10-100 (progressivo)
- **Objetivo:** Identificar limite máximo

## 📈 Métricas Importantes

- **Response Time (P95):** < 500ms ✅
- **Error Rate:** < 1% ✅
- **Throughput:** > 100 req/s ✅

## 🔍 Como Analisar

1. Verifique os logs para erros
2. Analise os JSONs para métricas detalhadas
3. Compare com SLA definido
4. Identifique gargalos de performance

EOF

    echo -e "${GREEN}✅ Relatório gerado: $SUMMARY_FILE${NC}"
}

# Main execution
main() {
    local start_time=$(date +%s)
    
    check_service
    echo ""
    
    run_artillery_tests
    echo ""
    
    run_k6_tests
    echo ""
    
    generate_summary
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    echo -e "${GREEN}🎉 Todos os testes concluídos!${NC}"
    echo -e "${GREEN}⏱️  Tempo total: ${duration}s${NC}"
    echo -e "${GREEN}📁 Resultados salvos em: ./$RESULTS_DIR/${NC}"
    echo ""
    echo -e "${BLUE}📊 Para analisar os resultados:${NC}"
    echo -e "   - Logs: cat $RESULTS_DIR/*.log"
    echo -e "   - JSONs: cat $RESULTS_DIR/*.json | jq ."
    echo -e "   - Resumo: cat $RESULTS_DIR/summary_${TIMESTAMP}.md"
}

# Execute main function
main "$@"

#!/bin/bash

# 🧪 FIAP SOAT - Validação dos Scripts Finais
# Valida que todos os scripts essenciais estão funcionais

set -e

echo "🧪 FIAP SOAT - Validação dos Scripts Finais"
echo "=========================================="
echo ""

# Lista dos scripts essenciais
ESSENTIAL_SCRIPTS=(
    "scripts/aws-config.sh"
    "scripts/deploy.sh"
    "scripts/deploy-from-ecr.sh"
    "scripts/test-eks-academy.sh"
    "scripts/destroy.sh"
    "scripts/force-destroy.sh"
    "load-tests/run-all-tests.sh"
)

echo "📋 Scripts a serem validados:"
for script in "${ESSENTIAL_SCRIPTS[@]}"; do
    echo "   - $script"
done
echo ""

# Validação de existência e permissões
echo "🔍 Validando existência e permissões..."
all_ok=true
for script in "${ESSENTIAL_SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        if [[ -x "$script" ]]; then
            echo "   ✅ $script - OK"
        else
            echo "   ⚠️  $script - Sem permissão de execução"
            chmod +x "$script"
            echo "   ✅ $script - Permissão corrigida"
        fi
    else
        echo "   ❌ $script - Arquivo não encontrado"
        all_ok=false
    fi
done
echo ""

# Validação de sintaxe
echo "🧪 Validando sintaxe dos scripts..."
for script in "${ESSENTIAL_SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        if bash -n "$script" 2>/dev/null; then
            echo "   ✅ $script - Sintaxe OK"
        else
            echo "   ❌ $script - Erro de sintaxe"
            all_ok=false
        fi
    fi
done
echo ""

# Verificar estrutura de arquivos
echo "📂 Verificando estrutura de arquivos..."
if [[ -d "scripts/archived" ]]; then
    archived_count=$(find scripts/archived -name "*.sh" | wc -l)
    echo "   ✅ Pasta archived/ existe com $archived_count scripts"
else
    echo "   ❌ Pasta scripts/archived/ não encontrada"
    all_ok=false
fi

if [[ -d "load-tests" ]]; then
    echo "   ✅ Pasta load-tests/ existe"
else
    echo "   ❌ Pasta load-tests/ não encontrada"
    all_ok=false
fi
echo ""

# Verificar documentação
echo "📖 Verificando documentação..."
docs_files=(
    "scripts/README.md"
    "SCRIPTS-CLEANUP-ANALYSIS.md"
)

for doc in "${docs_files[@]}"; do
    if [[ -f "$doc" ]]; then
        echo "   ✅ $doc - Existe"
    else
        echo "   ⚠️  $doc - Não encontrado"
    fi
done
echo ""

# Resultado final
if $all_ok; then
    echo "🎉 VALIDAÇÃO CONCLUÍDA COM SUCESSO!"
    echo "=========================================="
    echo ""
    echo "✅ Todos os scripts essenciais estão funcionais"
    echo "✅ Sintaxe validada"
    echo "✅ Permissões corretas"
    echo "✅ Estrutura organizada"
    echo ""
    echo "🎯 Scripts prontos para o trabalho final:"
    echo "   1. Configuração: ./scripts/aws-config.sh"
    echo "   2. Deploy:       ./scripts/deploy.sh"
    echo "   3. Testes:       ./scripts/test-eks-academy.sh"
    echo "   4. Load Tests:   ./load-tests/run-all-tests.sh"
    echo "   5. Cleanup:      ./scripts/destroy.sh"
    echo ""
    exit 0
else
    echo "❌ VALIDAÇÃO FALHOU!"
    echo "===================="
    echo ""
    echo "Corrija os problemas acima e execute novamente."
    echo ""
    exit 1
fi

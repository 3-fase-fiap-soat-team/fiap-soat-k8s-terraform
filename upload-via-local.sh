#!/bin/bash

# 🚀 FIAP SOAT - Script para Upload via Máquina Local
# Execute este script na sua máquina local após baixar o arquivo fiap-soat-nestjs-app.tar.gz

set -e

echo "🚀 FIAP SOAT - Upload da Imagem Docker via Máquina Local"
echo "======================================================="

# Configurações
ACCOUNT_ID="280273007505"
REGION="us-east-1"
REPOSITORY="fiap-soat-nestjs-app"
IMAGE_TAG="latest"
LOCAL_IMAGE="fiap-soat-nestjs-app:latest"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPOSITORY}:${IMAGE_TAG}"
TAR_FILE="fiap-soat-nestjs-app.tar.gz"

echo "📋 Configurações:"
echo "   Account ID: ${ACCOUNT_ID}"
echo "   Region: ${REGION}"
echo "   Repository: ${REPOSITORY}"
echo "   ECR URI: ${ECR_URI}"
echo "   Arquivo: ${TAR_FILE}"
echo ""

# Verificar se o arquivo existe
if [[ ! -f "${TAR_FILE}" ]]; then
    echo "❌ Arquivo ${TAR_FILE} não encontrado!"
    echo ""
    echo "📥 Para baixar o arquivo:"
    echo "   1. Acesse o ambiente remoto onde a imagem foi salva"
    echo "   2. Baixe o arquivo: /home/rafae/fiap-arch-software/fiap-soat-k8s-terraform/${TAR_FILE}"
    echo "   3. Coloque o arquivo no mesmo diretório deste script"
    echo ""
    exit 1
fi

echo "✅ Arquivo ${TAR_FILE} encontrado ($(du -h "${TAR_FILE}" | cut -f1))"

# Verificar se Docker está rodando
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker não está rodando!"
    echo "   Inicie o Docker Desktop e tente novamente"
    exit 1
fi

echo "✅ Docker está rodando"

# Descomprimir e carregar a imagem
echo "📦 Descomprimindo e carregando imagem no Docker local..."
gunzip -c "${TAR_FILE}" | docker load

# Verificar se a imagem foi carregada
echo "🔍 Verificando imagem carregada..."
if docker images "${LOCAL_IMAGE}" | grep -q "${LOCAL_IMAGE}"; then
    echo "✅ Imagem ${LOCAL_IMAGE} carregada com sucesso"
    docker images "${LOCAL_IMAGE}"
else
    echo "❌ Falha ao carregar a imagem"
    exit 1
fi

# Verificar se AWS CLI está configurado
echo "🔧 Verificando AWS CLI..."
if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "❌ AWS CLI não está configurado ou sem credenciais!"
    echo ""
    echo "📋 Configure suas credenciais AWS:"
    echo "   aws configure"
    echo "   ou"
    echo "   export AWS_ACCESS_KEY_ID=..."
    echo "   export AWS_SECRET_ACCESS_KEY=..."
    echo ""
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS CLI configurado - Account: ${AWS_ACCOUNT}"

if [[ "${AWS_ACCOUNT}" != "${ACCOUNT_ID}" ]]; then
    echo "⚠️  ATENÇÃO: Account ID diferente do esperado!"
    echo "   Esperado: ${ACCOUNT_ID}"
    echo "   Atual: ${AWS_ACCOUNT}"
    echo ""
    read -p "Continuar mesmo assim? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Verificar/criar repositório ECR
echo "🏗️  Verificando repositório ECR..."
if aws ecr describe-repositories --region "${REGION}" --repository-names "${REPOSITORY}" >/dev/null 2>&1; then
    echo "✅ Repositório ${REPOSITORY} já existe"
else
    echo "🆕 Criando repositório ${REPOSITORY}..."
    aws ecr create-repository \
        --region "${REGION}" \
        --repository-name "${REPOSITORY}" \
        --image-scanning-configuration scanOnPush=true
    echo "✅ Repositório criado com sucesso"
fi

# Login no ECR
echo "🔐 Fazendo login no ECR..."
aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

# Tag da imagem para ECR
echo "🏷️  Fazendo tag da imagem para ECR..."
docker tag "${LOCAL_IMAGE}" "${ECR_URI}"

# Push para ECR
echo "📤 Fazendo push para ECR..."
echo "   Isso pode demorar alguns minutos (~519MB)..."
docker push "${ECR_URI}"

# Verificar upload
echo "🔍 Verificando upload no ECR..."
aws ecr describe-images --region "${REGION}" --repository-name "${REPOSITORY}" --query 'imageDetails[*].[imageTags[0],imageSizeInBytes,imagePushedAt]' --output table

echo ""
echo "🎉 Upload concluído com sucesso!"
echo "=================================================="
echo "📋 Informações da Imagem ECR:"
echo "   URI: ${ECR_URI}"
echo "   Region: ${REGION}"
echo "   Repository: ${REPOSITORY}"
echo "   Tag: ${IMAGE_TAG}"
echo ""
echo "🚀 Próximo Passo - Deploy no EKS:"
echo "   Execute o script de deploy no ambiente remoto:"
echo "   cd /home/rafae/fiap-arch-software/fiap-soat-k8s-terraform"
echo "   ./scripts/deploy-from-ecr.sh"
echo ""
echo "🌐 Comandos úteis:"
echo "   # Verificar imagem no ECR"
echo "   aws ecr describe-images --region ${REGION} --repository-name ${REPOSITORY}"
echo ""
echo "   # Pull da imagem (para testar)"
echo "   docker pull ${ECR_URI}"
echo ""
echo "✨ Imagem FIAP SOAT NestJS disponível no ECR!"

# Limpeza opcional
echo ""
read -p "🗑️  Deseja remover a imagem local para liberar espaço? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker rmi "${LOCAL_IMAGE}" "${ECR_URI}" 2>/dev/null || true
    echo "✅ Imagens locais removidas"
fi

echo "🎯 Upload via máquina local concluído!"

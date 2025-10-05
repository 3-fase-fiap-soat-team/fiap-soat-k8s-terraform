#!/bin/bash

# FIAP SOAT - Script para Deploy da Aplicação NestJS Real via ECR
# Este script deploy a aplicação real do NestJS usando a imagem do ECR

set -e

echo "🚀 FIAP SOAT - Deploy da Aplicação Real NestJS via ECR"
echo "=================================================="

# Configurações
ACCOUNT_ID="280273007505"
REGION="us-east-1"
REPOSITORY="fiap-soat-nestjs-app"
IMAGE_TAG="latest"
ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPOSITORY}:${IMAGE_TAG}"

echo "📋 Configurações:"
echo "   Account ID: ${ACCOUNT_ID}"
echo "   Region: ${REGION}"
echo "   Repository: ${REPOSITORY}"
echo "   ECR URI: ${ECR_URI}"
echo ""

# Verificar se a imagem existe no ECR
echo "🔍 Verificando imagem no ECR..."
if aws ecr describe-images --region ${REGION} --repository-name ${REPOSITORY} --image-ids imageTag=${IMAGE_TAG} &>/dev/null; then
    echo "✅ Imagem encontrada no ECR"
else
    echo "❌ Imagem não encontrada no ECR!"
    echo "Execute primeiro o upload via console seguindo o guia ECR-UPLOAD-GUIDE.md"
    exit 1
fi

# Criar manifesto de deployment com ECR
echo "📄 Criando manifesto de deployment para aplicação real..."
cat > manifests/application/deployment-nestjs-real.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fiap-soat-nestjs-real
  namespace: fiap-soat
  labels:
    app: fiap-soat-nestjs-real
    version: v1
    tier: backend
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: fiap-soat-nestjs-real
  template:
    metadata:
      labels:
        app: fiap-soat-nestjs-real
        version: v1
        tier: backend
    spec:
      containers:
      - name: fiap-soat-nestjs
        image: ${ECR_URI}
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        - name: LOG_LEVEL
          value: "info"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
      imagePullSecrets:
      - name: ecr-secret
---
apiVersion: v1
kind: Service
metadata:
  name: fiap-soat-nestjs-real-service
  namespace: fiap-soat
  labels:
    app: fiap-soat-nestjs-real
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
    name: http
  selector:
    app: fiap-soat-nestjs-real
EOF

echo "✅ Manifesto criado: manifests/application/deployment-nestjs-real.yaml"

# Verificar se o namespace existe
echo "🔍 Verificando namespace..."
if ! kubectl get namespace fiap-soat &>/dev/null; then
    echo "📦 Criando namespace fiap-soat..."
    kubectl apply -f manifests/application/01-namespace.yaml
fi

# Criar secret para ECR
echo "🔐 Configurando secret para ECR..."
kubectl delete secret ecr-secret -n fiap-soat --ignore-not-found=true

# Obter token do ECR
ECR_TOKEN=$(aws ecr get-login-password --region ${REGION})
kubectl create secret docker-registry ecr-secret \
    --docker-server=${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com \
    --docker-username=AWS \
    --docker-password=${ECR_TOKEN} \
    --namespace=fiap-soat

echo "✅ Secret ECR criado"

# Deploy da aplicação
echo "🚀 Fazendo deploy da aplicação real..."
kubectl apply -f manifests/application/deployment-nestjs-real.yaml

# Aguardar deployment
echo "⏳ Aguardando deployment ficar pronto..."
kubectl wait --for=condition=available --timeout=300s deployment/fiap-soat-nestjs-real -n fiap-soat

# Obter informações do LoadBalancer
echo "🌐 Obtendo informações do LoadBalancer..."
echo "Aguardando LoadBalancer ficar disponível..."
kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0].hostname}' service/fiap-soat-nestjs-real-service -n fiap-soat --timeout=300s

LOAD_BALANCER=$(kubectl get service fiap-soat-nestjs-real-service -n fiap-soat -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo ""
echo "🎉 Deploy concluído com sucesso!"
echo "=================================================="
echo "📋 Informações da Aplicação:"
echo "   Namespace: fiap-soat"
echo "   Deployment: fiap-soat-nestjs-real"
echo "   Replicas: 2"
echo "   Imagem: ${ECR_URI}"
echo "   LoadBalancer: ${LOAD_BALANCER}"
echo ""
echo "🌐 URLs da Aplicação:"
echo "   Health Check: http://${LOAD_BALANCER}/health"
echo "   API Docs: http://${LOAD_BALANCER}/api"
echo "   Base URL: http://${LOAD_BALANCER}"
echo ""
echo "📊 Endpoints Disponíveis:"
echo "   GET  /health           - Health check"
echo "   GET  /api              - Swagger documentation"
echo "   GET  /clientes         - Listar clientes"
echo "   POST /clientes         - Criar cliente"
echo "   GET  /produtos         - Listar produtos"
echo "   POST /produtos         - Criar produto"
echo "   GET  /pedidos          - Listar pedidos"
echo "   POST /pedidos          - Criar pedido"
echo "   GET  /pagamentos       - Listar pagamentos"
echo "   POST /pagamentos       - Processar pagamento"
echo ""
echo "🔍 Comandos úteis:"
echo "   kubectl get pods -n fiap-soat"
echo "   kubectl logs -l app=fiap-soat-nestjs-real -n fiap-soat"
echo "   kubectl describe service fiap-soat-nestjs-real-service -n fiap-soat"
echo ""

# Teste básico
echo "🧪 Testando aplicação..."
if curl -s -f "http://${LOAD_BALANCER}/health" >/dev/null; then
    echo "✅ Aplicação respondendo corretamente!"
else
    echo "⚠️  Aguarde alguns minutos para a aplicação ficar completamente disponível"
fi

echo ""
echo "✨ Aplicação FIAP SOAT NestJS Real deployada com sucesso usando ECR!"

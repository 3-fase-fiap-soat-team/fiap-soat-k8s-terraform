#!/bin/bash

# FIAP SOAT - Build and Deploy Script
# Este script faz o build da aplicação e deploy no EKS

set -e

echo "🚀 FIAP SOAT - Build and Deploy Script"
echo "======================================"

# Variáveis
APP_DIR="/home/rafae/fiap-arch-software/fiap-soat-application"
K8S_DIR="/home/rafae/fiap-arch-software/fiap-soat-k8s-terraform"
DOCKER_IMAGE="fiapsoat/nestjs-app"
DOCKER_TAG="latest"
NAMESPACE="fiap-soat-app"

echo "📁 Navegando para o diretório da aplicação..."
cd "$APP_DIR"

echo "🧹 Limpando ambiente Docker existente..."
make clean 2>/dev/null || echo "Nenhum ambiente para limpar"

echo "🔨 Iniciando build da aplicação..."
make init

echo "⏳ Aguardando a aplicação subir completamente..."
sleep 60

echo "🏷️  Fazendo tag da imagem Docker..."
docker tag fiap-soat-application-api-dev:latest $DOCKER_IMAGE:$DOCKER_TAG

echo "📤 Fazendo push da imagem para Docker Hub..."
echo "⚠️  Certifique-se de estar logado no Docker Hub:"
echo "   docker login"
echo ""
read -p "Pressione Enter para continuar com o push ou Ctrl+C para cancelar..."

docker push $DOCKER_IMAGE:$DOCKER_TAG

echo "🎯 Navegando para diretório Kubernetes..."
cd "$K8S_DIR"

echo "🔄 Atualizando deployment no EKS..."
# Criar deployment com a imagem real
cat > manifests/application-nestjs/02-deployment-real.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fiap-soat-nestjs-real
  namespace: $NAMESPACE
  labels:
    app: fiap-soat-nestjs-real
    version: v1
    component: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: fiap-soat-nestjs-real
  template:
    metadata:
      labels:
        app: fiap-soat-nestjs-real
        version: v1
        component: backend
    spec:
      containers:
      - name: fiap-soat-nestjs
        image: $DOCKER_IMAGE:$DOCKER_TAG
        imagePullPolicy: Always
        ports:
        - name: http
          containerPort: 3000
          protocol: TCP
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        - name: DB_HOST
          value: "postgres-service"
        - name: DB_PORT
          value: "5432"
        - name: DB_USERNAME
          value: "postgres"
        - name: DB_PASSWORD
          value: "postgres123"
        - name: DB_DATABASE
          value: "soat_tech_challenge"
        - name: JWT_SECRET
          value: "fiap-soat-jwt-secret-key"
        - name: MERCADOPAGO_ACCESS_TOKEN
          value: "TEST-demo-token"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 60
          periodSeconds: 10
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 5
          failureThreshold: 3
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
EOF

# Criar serviço para a aplicação real
cat > manifests/application-nestjs/03-service-real.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: fiap-soat-nestjs-real-service
  namespace: $NAMESPACE
  labels:
    app: fiap-soat-nestjs-real
    component: backend
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
spec:
  type: LoadBalancer
  selector:
    app: fiap-soat-nestjs-real
  ports:
  - name: http
    port: 80
    targetPort: 3000
    protocol: TCP
  sessionAffinity: None
EOF

echo "📋 Aplicando manifests no EKS..."
kubectl apply -f manifests/application-nestjs/02-deployment-real.yaml
kubectl apply -f manifests/application-nestjs/03-service-real.yaml

echo "⏳ Aguardando pods ficarem prontos..."
kubectl wait --for=condition=ready pod -l app=fiap-soat-nestjs-real -n $NAMESPACE --timeout=300s

echo "🌐 Obtendo URL do LoadBalancer..."
kubectl get service fiap-soat-nestjs-real-service -n $NAMESPACE

echo ""
echo "✅ Deploy concluído com sucesso!"
echo "🔗 Acesse a aplicação através do EXTERNAL-IP mostrado acima"
echo "📝 Endpoints disponíveis:"
echo "   - GET  / (status da API)"
echo "   - GET  /health (health check)"
echo "   - GET  /categories (categorias)"
echo "   - GET  /products (produtos)"
echo "   - POST /customers (criar cliente)"
echo "   - POST /orders (criar pedido)"

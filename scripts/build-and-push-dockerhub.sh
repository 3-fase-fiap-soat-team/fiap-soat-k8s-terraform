#!/bin/bash

# FIAP SOAT - Build Real Application and Push to Docker Hub
# Este script constrói a aplicação real NestJS e faz push para Docker Hub

set -e

echo "🚀 FIAP SOAT - Build Real Application for Docker Hub/EKS"
echo "======================================================"

# Variáveis
APP_DIR="/home/rafae/fiap-arch-software/fiap-soat-application"
K8S_DIR="/home/rafae/fiap-arch-software/fiap-soat-k8s-terraform"
DOCKER_USERNAME="fiapsoat"  # Username genérico para demo
REPOSITORY_NAME="nestjs-app"
DOCKER_IMAGE="${DOCKER_USERNAME}/${REPOSITORY_NAME}"
DOCKER_TAG="latest"
NAMESPACE="fiap-soat-app"

echo "📋 Configuração:"
echo "   Docker Hub Repository: $DOCKER_IMAGE"
echo "   Tag: $DOCKER_TAG"
echo "   Full Docker URI: $DOCKER_IMAGE:$DOCKER_TAG"
echo ""

echo "📁 Navegando para o diretório da aplicação..."
cd "$APP_DIR"

echo "🧹 Limpando ambiente Docker existente..."
make clean 2>/dev/null || echo "Nenhum ambiente para limpar"

echo "🔨 Iniciando build da aplicação NestJS real..."
make init

echo "⏳ Aguardando a aplicação subir completamente..."
sleep 60

echo "🏷️  Fazendo tag da imagem para Docker Hub..."
docker tag fiap-soat-application-api-dev:latest $DOCKER_IMAGE:$DOCKER_TAG

echo "📋 Verificando imagens Docker criadas..."
docker images | grep -E "(fiap-soat|${DOCKER_USERNAME})"

echo ""
echo "⚠️  ATENÇÃO: Para fazer push para Docker Hub, você precisa:"
echo "   1. Ter uma conta no Docker Hub"
echo "   2. Executar: docker login"
echo "   3. Usar seu próprio username/repository"
echo ""
read -p "Deseja continuar com o push? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 Fazendo push da imagem para Docker Hub..."
    echo "Se não conseguir fazer push, a imagem local estará disponível como: $DOCKER_IMAGE:$DOCKER_TAG"
    docker push $DOCKER_IMAGE:$DOCKER_TAG || {
        echo "❌ Push falhou. Isso é esperado se você não tem acesso ao repositório $DOCKER_USERNAME"
        echo "💡 Para usar sua própria conta Docker Hub:"
        echo "   1. Altere DOCKER_USERNAME no script para seu username"
        echo "   2. Execute: docker login"
        echo "   3. Execute novamente o script"
        echo ""
        echo "⏭️  Continuando com deploy usando imagem local..."
    }
fi

echo ""
echo "🎯 Navegando para diretório Kubernetes..."
cd "$K8S_DIR"

echo "🔄 Criando deployment para usar imagem Docker Hub..."
cat > manifests/application-nestjs/02-deployment-dockerhub.yaml << EOF
# FIAP SOAT - Real NestJS Application Deployment using Docker Hub
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fiap-soat-nestjs-real
  namespace: $NAMESPACE
  labels:
    app: fiap-soat-nestjs-real
    version: v1
    component: backend
    source: dockerhub
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
        source: dockerhub
    spec:
      containers:
      - name: fiap-soat-nestjs
        image: $DOCKER_IMAGE:$DOCKER_TAG
        imagePullPolicy: IfNotPresent  # Usar imagem local se push falhou
        ports:
        - name: http
          containerPort: 3000
          protocol: TCP
        env:
        - name: NODE_ENV
          value: "production"
        - name: PORT
          value: "3000"
        # Configurações básicas para demo (em produção usar ConfigMap/Secrets)
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
          value: "fiap-soat-jwt-secret-key-prod"
        - name: MERCADOPAGO_ACCESS_TOKEN
          value: "TEST-demo-token"
        # Health checks específicos para NestJS
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 60
          periodSeconds: 15
          failureThreshold: 3
          timeoutSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
          failureThreshold: 3
          timeoutSeconds: 5
        # Resource limits otimizados para NestJS
        resources:
          requests:
            memory: "768Mi"
            cpu: "300m"
          limits:
            memory: "1.5Gi"
            cpu: "800m"
EOF

# Criar serviço para a aplicação real
cat > manifests/application-nestjs/03-service-real.yaml << EOF
# FIAP SOAT - Real NestJS Service
apiVersion: v1
kind: Service
metadata:
  name: fiap-soat-nestjs-real-service
  namespace: $NAMESPACE
  labels:
    app: fiap-soat-nestjs-real
    component: backend
    source: dockerhub
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    service.beta.kubernetes.io/aws-load-balancer-attributes: "load_balancing.cross_zone.enabled=true"
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

echo "🛑 Removendo deployments anteriores..."
kubectl delete deployment fiap-soat-nestjs-enhanced -n $NAMESPACE --ignore-not-found=true

echo "📋 Aplicando manifests da aplicação REAL no EKS..."
kubectl apply -f manifests/application-nestjs/02-deployment-dockerhub.yaml
kubectl apply -f manifests/application-nestjs/03-service-real.yaml

echo "⏳ Aguardando pods ficarem prontos..."
echo "Isso pode demorar alguns minutos para o pull da imagem e inicialização do NestJS..."
kubectl wait --for=condition=ready pod -l app=fiap-soat-nestjs-real -n $NAMESPACE --timeout=600s

echo ""
echo "🌐 Obtendo URL do LoadBalancer..."
kubectl get service fiap-soat-nestjs-real-service -n $NAMESPACE

echo ""
echo "✅ Deploy da aplicação REAL FIAP SOAT concluído com sucesso!"
echo "🏗️  Imagem: $DOCKER_IMAGE:$DOCKER_TAG"
echo "🔗 Acesse a aplicação através do EXTERNAL-IP mostrado acima"
echo ""
echo "📝 Endpoints da aplicação REAL NestJS disponíveis:"
echo "   🏠 GET  / (status da API NestJS real)"
echo "   ❤️  GET  /health (health check detalhado)"
echo "   📂 GET  /categories (categorias de produtos com dados reais)"
echo "   🛍️  GET  /products (produtos com preços e estoque)"
echo "   🔍 GET  /products/:id (produto específico)"
echo "   👥 GET  /customers (listar clientes cadastrados)"
echo "   🔎 GET  /customers/:cpf (buscar cliente por CPF)"
echo "   ➕ POST /customers (criar novo cliente)"
echo "   📦 GET  /orders (listar todos os pedidos)"
echo "   🔍 GET  /orders/:id (detalhes do pedido)"
echo "   👨‍🍳 GET  /orders/kitchen (pedidos para cozinha)"
echo "   🛒 POST /orders (criar novo pedido)"
echo "   💳 POST /orders/:id/payment-qrcode (gerar QR code MercadoPago)"
echo "   🍳 PATCH /orders/:id/prepare (marcar pedido em preparo)"
echo "   ✅ PATCH /orders/:id/finalize (finalizar pedido)"
echo "   🚚 PATCH /orders/:id/deliver (entregar pedido)"
echo "   💰 POST /webhook/mercadopago (webhook do Mercado Pago)"
echo ""
echo "🎯 A aplicação REAL FIAP SOAT NestJS está rodando no EKS!"

echo ""
echo "🧹 Aguardando alguns minutos antes de limpar containers locais..."
sleep 30

# Cleanup: parar containers locais para liberar recursos
echo "🧹 Limpando containers locais para liberar recursos..."
cd "$APP_DIR"
make clean 2>/dev/null || echo "Nenhum container local para limpar"

echo ""
echo "🎉 Processo completo finalizado!"
echo "🚀 Sua aplicação FIAP SOAT NestJS real está rodando no AWS EKS!"
EOF

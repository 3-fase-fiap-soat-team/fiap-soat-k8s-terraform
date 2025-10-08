# Seção de Testes para o README.md

Inserir ANTES da seção "Estrutura do Repositório"

## 🧪 Como Testar o Sistema

### 1️⃣ Verificar Infraestrutura

```bash
# Cluster EKS
kubectl cluster-info

# Nodes disponíveis
kubectl get nodes

# Pods rodando
kubectl get pods -n fiap-soat-app

# Services e Load Balancer
kubectl get service -n fiap-soat-app

# HPA (Autoscaling)
kubectl get hpa -n fiap-soat-app
```

### 2️⃣ Health Check da Aplicação

```bash
# Pegar URL do Load Balancer
export LB_URL=$(kubectl get service -n fiap-soat-app fiap-soat-application-service \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Testar health
curl http://$LB_URL/health
```

**Resposta esperada**:
```json
{
  "status": "ok",
  "info": {
    "database": { "status": "up" },
    "memory": { "status": "up" }
  }
}
```

### 3️⃣ Swagger UI (Documentação Interativa)

```bash
# Abrir no navegador
echo "http://$LB_URL/docs"
```

Acesse a URL no navegador para ver a documentação interativa da API e testar endpoints.

### 4️⃣ Fluxo Completo de Pedido

#### A. Cadastrar Cliente (via Lambda /signup)

```bash
# 1. Pegar URL do API Gateway
export API_URL="https://nlxpeaq6w0.execute-api.us-east-1.amazonaws.com/dev"

# 2. Cadastrar cliente
curl -X POST $API_URL/signup \
  -H "Content-Type: application/json" \
  -d '{
    "cpf": "12345678900",
    "name": "João Silva",
    "email": "joao@example.com"
  }'
```

**Resposta**:
```json
{
  "message": "User created successfully",
  "user": {
    "cpf": "12345678900",
    "name": "João Silva",
    "email": "joao@example.com"
  }
}
```

#### B. Autenticar e Obter JWT (via Lambda /auth)

```bash
# 1. Autenticar com CPF
curl -X POST $API_URL/auth \
  -H "Content-Type: application/json" \
  -d '{"cpf": "12345678900"}'

# Salvar token JWT da resposta
export JWT_TOKEN="<copiar accessToken da resposta>"
```

**Resposta**:
```json
{
  "accessToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "idToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJjdHkiOiJKV1QiLCJlbmMiOiJBMjU2R0NNIi...",
  "expiresIn": 3600
}
```

#### C. Consultar Produtos

```bash
# Listar produtos disponíveis
curl http://$LB_URL/products
```

#### D. Criar Pedido

```bash
curl -X POST http://$LB_URL/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{
    "customerId": "12345678900",
    "items": [
      {
        "productId": 1,
        "quantity": 2,
        "notes": "Sem cebola"
      },
      {
        "productId": 3,
        "quantity": 1
      }
    ]
  }'
```

**Resposta**:
```json
{
  "id": 1,
  "customerId": "12345678900",
  "status": "PENDENTE_PAGAMENTO",
  "total": 45.50,
  "createdAt": "2025-10-07T10:30:00Z"
}
```

#### E. Consultar Pedido

```bash
# Por ID
curl http://$LB_URL/orders/1

# Todos os pedidos
curl http://$LB_URL/orders

# Por status
curl http://$LB_URL/orders?status=PENDENTE_PAGAMENTO
```

### 5️⃣ Testes de Carga

```bash
# Rodar todos os testes
cd load-tests
./run-all-tests.sh

# OU rodar individualmente

# Artillery (HTTP load testing)
cd artillery
npm install
npm run test:basic
npm run test:spike

# K6 (Performance testing)
cd ../k6
k6 run --vus 10 --duration 30s basic-load-test.js
```

**Métricas esperadas**:
- **Latência p95**: < 500ms
- **Taxa de erro**: < 1%
- **Throughput**: > 100 req/s

### 6️⃣ Monitorar HPA (Autoscaling)

```bash
# Ver status do autoscaler
kubectl get hpa -n fiap-soat-app

# Acompanhar em tempo real
kubectl get hpa -n fiap-soat-app -w

# Ver eventos de scaling
kubectl describe hpa -n fiap-soat-app fiap-soat-application-hpa

# Monitorar pods escalando durante carga
kubectl get pods -n fiap-soat-app -w
```

### 7️⃣ Monitorar Logs

```bash
# Logs da aplicação
kubectl logs -n fiap-soat-app deployment/fiap-soat-application --tail=100 -f

# Logs de um pod específico
kubectl logs -n fiap-soat-app <POD_NAME> -f

# Eventos do namespace
kubectl get events -n fiap-soat-app --sort-by='.lastTimestamp'
```

### 8️⃣ Troubleshooting

#### Pod não está Ready
```bash
kubectl describe pod -n fiap-soat-app <POD_NAME>
kubectl logs -n fiap-soat-app <POD_NAME>
```

#### Service sem Endpoints
```bash
kubectl get endpoints -n fiap-soat-app
# Se <none>, deployment ainda não foi criado pelo repositório da aplicação
```

#### Load Balancer em Pending
```bash
kubectl describe service -n fiap-soat-app fiap-soat-application-service
# Aguardar ~2-3min para AWS provisionar NLB
```

#### HPA não escala (métricas <unknown>)
```bash
# Instalar Metrics Server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verificar
kubectl top nodes
kubectl top pods -n fiap-soat-app
```

---

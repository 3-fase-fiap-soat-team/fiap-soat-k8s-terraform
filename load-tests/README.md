# Testes de Carga - FIAP SOAT Application

Este diretório contém testes de performance/carga para validar a aplicação NestJS no EKS.

## 🛠️ **Ferramentas de Teste**

- **Artillery**: Testes de carga HTTP
- **K6**: Performance e stress tests
- **Newman**: Testes Postman automatizados

## 📋 **Cenários de Teste**

### 1. **Smoke Tests**
- Verificação básica de endpoints
- 1-5 usuários por 30 segundos

### 2. **Load Tests**
- Carga normal esperada
- 10-50 usuários por 5 minutos

### 3. **Stress Tests**
- Identificar limite máximo
- 100-500 usuários por 10 minutos

### 4. **Spike Tests**
- Picos súbitos de tráfego
- 0-200 usuários instantâneo

## 🚀 **Execução**

```bash
# Instalar dependências
npm install -g artillery k6

# Executar smoke test
artillery run artillery/smoke-test.yml

# Executar load test
k6 run k6/load-test.js

# Executar todos os testes
./run-all-tests.sh
```

## 📊 **Métricas Monitoradas**

- **Response Time**: P95 < 500ms
- **Throughput**: > 100 req/s
- **Error Rate**: < 1%
- **CPU Usage**: < 80%
- **Memory Usage**: < 512Mi

## 🎯 **Endpoints Testados**

Baseado na API da aplicação NestJS:

- `GET /health` - Health check
- `POST /auth/login` - Autenticação
- `GET /customers` - Listar clientes
- `POST /customers` - Criar cliente
- `GET /products` - Listar produtos
- `POST /orders` - Criar pedido
- `POST /payments` - Processar pagamento

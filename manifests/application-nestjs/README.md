# 📁 Manifests Kubernetes - FIAP SOAT NestJS

Esta pasta contém todos os manifests Kubernetes para deploy da aplicação FIAP SOAT NestJS no EKS.

## 📋 Estrutura de Arquivos

### 🟢 Arquivos Ativos (Em Uso)
```
01-namespace.yaml           # Namespace + ConfigMap + Secrets
02-deployment.yaml          # Deployment atual (nginx temporário)
03-service.yaml            # Services (LoadBalancer + ClusterIP)
```

### 📝 Templates para Produção
```
02-deployment-production.yaml.template    # Template para aplicação NestJS real
03-service-production.yaml.template       # Template para services de produção
```

## 🚀 Status Atual

### ✅ O que está funcionando:
- **Namespace**: `fiap-soat-app` criado com configurações
- **Deployment**: 2 pods nginx:alpine rodando (demo)
- **Service**: LoadBalancer exposto publicamente
- **URL**: http://aceb78fa8084e45afbbd4782ad7683b8-f41507c5845b5427.elb.us-east-1.amazonaws.com

### 📋 Configurações Aplicadas:
- **ConfigMap**: Variáveis de ambiente da aplicação
- **Secrets**: Credenciais de banco e JWT
- **ServiceAccount**: Conta de serviço com permissões

## 🔄 Deploy dos Manifests

### Ordem de Aplicação:
```bash
# 1. Namespace e configurações
kubectl apply -f 01-namespace.yaml

# 2. Deployment da aplicação
kubectl apply -f 02-deployment.yaml

# 3. Services para exposição
kubectl apply -f 03-service.yaml
```

### Verificação:
```bash
# Status geral
kubectl get all -n fiap-soat-app

# Pods detalhados
kubectl get pods -n fiap-soat-app -o wide

# Services e endpoints
kubectl get svc -n fiap-soat-app
```

## 🔧 Configuração Atual vs Produção

### Current (Demo):
- **Imagem**: `nginx:alpine`
- **Porta**: 80
- **Health Check**: `/` (nginx default)
- **Resources**: Baixo (64Mi RAM, 50m CPU)

### Production (Template):
- **Imagem**: `fiap-soat/nestjs-app:latest` 
- **Porta**: 3000
- **Health Check**: `/health` (NestJS endpoint)
- **Resources**: Médio (256Mi RAM, 100m CPU)
- **Env Vars**: Completas (DB, JWT, Cognito)

## 🎯 Próximos Passos

### Para usar a aplicação NestJS real:

1. **Build da imagem Docker**:
   ```bash
   # No repo fiap-soat-application
   docker build -t fiap-soat/nestjs-app:latest .
   docker push fiap-soat/nestjs-app:latest
   ```

2. **Substituir deployment**:
   ```bash
   # Usar template de produção
   cp 02-deployment-production.yaml.template 02-deployment.yaml
   cp 03-service-production.yaml.template 03-service.yaml
   ```

3. **Aplicar mudanças**:
   ```bash
   kubectl apply -f 02-deployment.yaml
   kubectl apply -f 03-service.yaml
   ```

## 📊 Resources e Limits

### Configuração Atual (nginx):
```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "200m"
```

### Configuração Produção (NestJS):
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

## 🔒 Security Context

### Aplicado:
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- `capabilities.drop: ALL`
- ReadOnlyRootFilesystem (quando possível)

## 🏷️ Labels e Annotations

### Labels Padrão:
```yaml
app: fiap-soat-nestjs
version: v1
component: backend
```

### Annotations para Monitoring:
```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "3000"
prometheus.io/path: "/metrics"
```

---

## 📝 Notas

- **AWS Academy**: Configurações otimizadas para instâncias pequenas
- **High Availability**: Anti-affinity rules para distribuir pods
- **Monitoring Ready**: Preparado para Prometheus/Grafana
- **Production Ready**: Templates prontos para aplicação real

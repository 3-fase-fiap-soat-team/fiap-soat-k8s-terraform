# 🗄️ Integração com Banco de Dados - Plano Futuro

## 📋 **Status Atual**
- ✅ **Aplicação NestJS**: Deployada e rodando no EKS
- ✅ **Modo**: Desenvolvimento (sem BD obrigatório)  
- ✅ **LoadBalancer**: Funcionando
- ⏳ **BD**: Será provisionado via Terraform separado

---

## 🎯 **Plano de Integração com BD**

### **Fase 1: Provisionar BD via Terraform** (Repo separado)
```bash
# No repo fiap-soat-database-terraform
terraform apply
```

**Recursos que serão criados:**
- RDS PostgreSQL
- Security Groups
- Subnet Groups
- Parameter Groups
- Backup automatizado

### **Fase 2: Atualizar Secrets Kubernetes**
```yaml
# Atualizar fiap-soat-nestjs-secrets com dados reais
apiVersion: v1
kind: Secret
metadata:
  name: fiap-soat-nestjs-secrets
  namespace: fiap-soat-app
data:
  DB_HOST: <base64-encoded-rds-endpoint>
  DB_PORT: NTQzMg==  # 5432
  DB_USERNAME: <base64-encoded-username>
  DB_PASSWORD: <base64-encoded-password>  
  DB_DATABASE: <base64-encoded-database-name>
```

### **Fase 3: Migrar para Deployment de Produção**
```bash
# Usar template de produção
cp manifests/application-nestjs/02-deployment-production.yaml.template \
   manifests/application-nestjs/02-deployment-production.yaml

# Ajustar para ECR
sed -i 's|fiap-soat/nestjs-app:latest|280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest|' \
       manifests/application-nestjs/02-deployment-production.yaml

# Aplicar
kubectl apply -f manifests/application-nestjs/02-deployment-production.yaml
```

---

## 🔧 **Configurações que Mudarão**

### **Atual (Sem BD):**
- `NODE_ENV: "development"`
- `DB_HOST: "localhost"` (dummy)
- Health checks desabilitados
- 1 replica
- Resources reduzidos

### **Futuro (Com BD):**
- `NODE_ENV: "production"`
- `DB_HOST: <rds-endpoint>`
- Health checks `/health` habilitados
- 2+ replicas
- Resources normais
- Migrations automáticas

---

## 📝 **Comandos Preparados**

### **Verificar BD quando disponível:**
```bash
# Testar conexão
kubectl exec -n fiap-soat-app deployment/fiap-soat-nestjs -- \
  npx typeorm query "SELECT NOW()"
```

### **Executar migrations:**
```bash
# Rodar migrations
kubectl exec -n fiap-soat-app deployment/fiap-soat-nestjs -- \
  npm run migration:run
```

### **Monitorar logs:**
```bash
# Logs da aplicação
kubectl logs -n fiap-soat-app -l app=fiap-soat-nestjs -f
```

---

## 🏗️ **Arquitetura Final (Com BD)**

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   LoadBalancer  │───▶│   EKS Cluster    │───▶│   RDS PostgreSQL │
│   (AWS ELB)     │    │   (NestJS Pods)  │    │   (Managed DB)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
       │                        │                        │
       │                        │                        │
   Internet                 K8s Services            Private Subnet
   Access                   & Ingress               (Security Groups)
```

---

## 🚨 **Pontos de Atenção**

1. **Security Groups**: BD deve aceitar conexões do EKS
2. **Credentials**: Nunca commitar senhas reais
3. **Migrations**: Executar antes do deploy
4. **Health Checks**: Só habilitar após BD estar OK
5. **Monitoring**: Configurar alertas para BD e App

---

## ⚡ **Quick Commands**

```bash
# Status atual
kubectl get all -n fiap-soat-app

# Logs
kubectl logs -n fiap-soat-app -l app=fiap-soat-nestjs --tail=50

# Atualizar deployment
kubectl rollout restart deployment/fiap-soat-nestjs -n fiap-soat-app

# Port-forward para testes
kubectl port-forward -n fiap-soat-app svc/fiap-soat-nestjs 8080:80
```

**🎯 A aplicação está pronta para receber o BD quando disponível!**
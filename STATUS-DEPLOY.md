# 🚀 Status do Deploy - FIAP SOAT Tech Challenge Fase 3

**Data**: 05/10/2025  
**Status**: ⏸️ PAUSADO - Deploy com timeout, recursos ativos na AWS

---

## ✅ O que está PRONTO e FUNCIONANDO:

### 1. Infraestrutura AWS
- ✅ **EKS Cluster**: `fiap-soat-eks-dev` (Kubernetes 1.30)
- ✅ **Node Group**: 2 nodes t3.micro (min:1 max:3)
- ✅ **RDS PostgreSQL**: `fiap-soat-db` (17.4) - **ATIVO**
- ✅ **VPC**: `vpc-0b339aae01a928665`
- ✅ **Subnets**: 5 filtradas (excluindo us-east-1e)
- ✅ **Security Groups**: Configurados para EKS + RDS

### 2. Aplicação
- ✅ **Imagem Docker**: Publicada no ECR
  - URI: `280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-rds-app:latest`
  - Tamanho: 2.24GB
  - NestJS com Clean Architecture
  - Configurado para RDS com SSL

### 3. Manifests Kubernetes
- ✅ **Namespace**: `fiap-soat-app`
- ✅ **ConfigMap**: Variáveis RDS (host, port, database)
- ✅ **Secret**: Senha do PostgreSQL
- ✅ **Deployment**: 2 réplicas, health probes
- ✅ **Service**: ClusterIP (porta 80 → 3000)

### 4. CI/CD
- ✅ **Workflows separados**:
  - `terraform-eks.yml` - Infraestrutura
  - `deploy-app.yml` - Aplicação (pode ser executado manualmente)

---

## ⚠️ PROBLEMA ATUAL:

### Timeout no Deploy
- **Workflow**: `deploy-app.yml` 
- **Step**: "Wait for Deployment Rollout" (timeout 5min)
- **Causa provável**: Pods não passando health check `/health`

### Possíveis motivos:
1. 🔴 Pods não conseguem conectar ao RDS
2. 🔴 Health probes muito agressivos (initialDelaySeconds: 20s)
3. 🔴 Aplicação demorando para inicializar
4. 🔴 Security groups bloqueando comunicação

---

## 🔧 PRÓXIMOS PASSOS (quando retomar):

### 1. Diagnosticar o problema

```bash
# Verificar status dos pods
kubectl get pods -n fiap-soat-app -o wide

# Ver eventos do namespace
kubectl get events -n fiap-soat-app --sort-by='.lastTimestamp'

# Ver logs da aplicação
kubectl logs -n fiap-soat-app -l app=fiap-soat-nestjs --tail=100

# Descrever pod para ver eventos
kubectl describe pod -n fiap-soat-app -l app=fiap-soat-nestjs
```

### 2. Ajustes possíveis

#### Opção A: Aumentar tempo dos health probes
Editar `manifests/deployment.yaml`:
```yaml
livenessProbe:
  initialDelaySeconds: 60  # era 30
  timeoutSeconds: 10       # era 5
  failureThreshold: 5      # era 3

readinessProbe:
  initialDelaySeconds: 40  # era 20
  timeoutSeconds: 10       # era 3
  failureThreshold: 5      # era 3
```

#### Opção B: Testar conectividade RDS manualmente
```bash
# Criar um pod temporário para testar
kubectl run -it --rm debug --image=postgres:17 -n fiap-soat-app -- bash

# Dentro do pod:
psql -h fiap-soat-db.cfcimi4ia52v.us-east-1.rds.amazonaws.com \
     -U postgresadmin -d fiapdb_dev
# Senha: SuperSecret123!
```

#### Opção C: Ver logs detalhados do pod
```bash
# Exec no pod (se ele estiver rodando)
POD=$(kubectl get pod -n fiap-soat-app -l app=fiap-soat-nestjs -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n fiap-soat-app $POD -- /bin/bash

# Verificar variáveis de ambiente
kubectl exec -n fiap-soat-app $POD -- env | grep DATABASE
```

### 3. Re-executar deploy

```bash
# Método 1: Via GitHub Actions
gh workflow run deploy-app.yml

# Método 2: Manualmente
cd manifests
kubectl apply -f .
kubectl rollout restart deployment/fiap-soat-nestjs -n fiap-soat-app
```

### 4. Verificar security groups

```bash
# Ver SG do node group
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=*fiap-soat-eks-dev-node*" \
  --query 'SecurityGroups[*].[GroupId,GroupName]'

# Ver regras de egress (deve permitir 5432 para RDS)
aws ec2 describe-security-groups \
  --group-ids <SG_ID> \
  --query 'SecurityGroups[*].IpPermissionsEgress'
```

---

## 💰 RECURSOS ATIVOS (CUSTOS)

### ⚠️ Com custo:
- **EKS Cluster**: ~$0.10/hora ($2.40/dia)
- **EC2 Nodes**: 2x t3.micro ~$0.02/hora ($0.96/dia)
- **RDS**: db.t3.micro ~$0.034/hora ($0.82/dia)
- **Total estimado**: ~$4.18/dia

### ✅ Sem custo adicional:
- ECR (storage mínimo)
- VPC, Subnets, IGW (free tier)
- Security Groups (free)

---

## 📁 ARQUIVOS IMPORTANTES

### Repositórios:
- **Infra**: `fiap-soat-k8s-terraform` (main branch)
- **App**: `fiap-soat-application` (feature/dev branch)

### Arquivos chave:
```
fiap-soat-k8s-terraform/
├── .github/workflows/
│   ├── deploy-app.yml          # Deploy aplicação
│   ├── terraform-eks.yml       # Deploy infraestrutura
│   └── README.md               # Documentação workflows
├── manifests/
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── deployment.yaml         # PODE PRECISAR AJUSTAR PROBES
│   └── service.yaml
└── environments/dev/
    ├── main.tf                 # VPC discovery via RDS
    └── terraform.tfvars        # Configuração EKS
```

---

## 🎯 OBJETIVO FINAL

Aplicação NestJS rodando no EKS, conectada ao RDS PostgreSQL, respondendo nos endpoints:
- `GET /health` - Health check
- `GET /products` - Lista produtos
- `POST /orders` - Criar pedido
- etc.

---

## 📞 COMANDOS ÚTEIS

```bash
# Status geral do cluster
kubectl cluster-info
kubectl get nodes
kubectl get all -n fiap-soat-app

# Logs em tempo real
kubectl logs -n fiap-soat-app -l app=fiap-soat-nestjs -f

# Port-forward para teste local
kubectl port-forward -n fiap-soat-app svc/fiap-soat-nestjs-service 8080:80
# Testar: curl http://localhost:8080/health

# Deletar e recriar deployment
kubectl delete deployment fiap-soat-nestjs -n fiap-soat-app
kubectl apply -f manifests/deployment.yaml

# Ver último workflow
gh run list --workflow=deploy-app.yml --limit 1
gh run view <RUN_ID> --log
```

---

## ✅ CHECKLIST PARA RETOMAR:

- [ ] Verificar se recursos AWS ainda estão ativos
- [ ] Ver logs dos pods que falharam
- [ ] Identificar causa do timeout
- [ ] Ajustar health probes se necessário
- [ ] Testar conectividade RDS manualmente
- [ ] Re-executar deploy
- [ ] Validar aplicação respondendo
- [ ] Testar endpoints da API
- [ ] Documentar solução final

---

**Última atualização**: 05/10/2025 - 14:30  
**Status**: Infraestrutura funcionando, aplicação com problema de health check

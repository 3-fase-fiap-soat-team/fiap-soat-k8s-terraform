# GitHub Actions Workflows

Este repositório possui 2 workflows separados:

## 🏗️ 1. Terraform CI/CD - EKS (`terraform-eks.yml`)

**Propósito**: Gerenciar infraestrutura do cluster EKS

**Quando executa**:
- Pull Requests → `terraform plan`
- Push na main → `terraform apply` (com `continue-on-error: true`)

**O que faz**:
- ✅ Valida código Terraform
- ✅ Cria/atualiza cluster EKS (se não existir)
- ⚠️ **Limitação**: Sem backend S3, pode falhar se cluster já existe

**Recursos gerenciados**:
- Cluster EKS
- Node Groups
- Security Groups
- Add-ons (coredns, vpc-cni, kube-proxy)

---

## 🚀 2. Deploy Application to EKS (`deploy-app.yml`)

**Propósito**: Fazer deploy da aplicação NestJS no cluster existente

**Quando executa**:
- Push na main (mudanças em `manifests/`)
- Manual via `workflow_dispatch`

**O que faz**:
- ✅ Conecta no cluster EKS existente
- ✅ Aplica manifests Kubernetes
- ✅ Aguarda rollout completar
- ✅ Verifica health e logs

**Recursos gerenciados**:
- Namespace `fiap-soat-app`
- ConfigMap (variáveis RDS)
- Secret (senha banco)
- Deployment (aplicação NestJS)
- Service (ClusterIP)

---

## 🎯 Uso Recomendado

### Deploy inicial (cluster novo):
1. Push na `main` → `terraform-eks.yml` cria o cluster
2. Executar manualmente `deploy-app.yml` → Deploy da aplicação

### Deploy de atualizações da aplicação:
- Push em `manifests/` → `deploy-app.yml` atualiza automaticamente

### Deploy manual:
```bash
gh workflow run deploy-app.yml
```

---

## ⚙️ Secrets Necessários

Configure em Settings → Secrets → Actions:

- `AWS_DEFAULT_REGION`: us-east-1
- `AWS_ACCESS_KEY_ID`: Sua access key
- `AWS_SECRET_ACCESS_KEY`: Sua secret key
- `AWS_SESSION_TOKEN`: Session token (AWS Academy)

# 🚀 FIAP SOAT - Sistema de Fast Food

**Infraestrutura como Código para Kubernetes na AWS**

[![Deploy EKS Infrastructure](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/actions/workflows/deploy-eks-infra.yml/badge.svg?branch=main)](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/actions/workflows/deploy-eks-infra.yml)
[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS EKS](https://img.shields.io/badge/AWS-EKS%201.30-FF9900?logo=amazon-aws)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.30-326CE5?logo=kubernetes)](https://kubernetes.io/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [Arquitetura](#-arquitetura)
- [Stack Tecnológica](#-stack-tecnológica)
- [Pré-requisitos](#-pré-requisitos)
- [Como Deployar](#-como-deployar)
- [Guia Completo de Testes](#-guia-completo-de-testes)
- [Estrutura do Repositório](#-estrutura-do-repositório)
- [Comandos Úteis](#-comandos-úteis)
- [Branches e Repositórios](#-branches-e-repositórios)
- [Equipe](#-equipe)

---

## 📖 Sobre o Projeto

Este projeto implementa a **infraestrutura completa de um sistema de fast food** utilizando:

- **Amazon EKS (Elastic Kubernetes Service)** para orquestração de containers
- **Terraform** para provisionamento de infraestrutura como código
- **AWS RDS PostgreSQL** para persistência de dados
- **AWS Lambda + API Gateway + Cognito** para autenticação serverless
- **Network Load Balancer** para exposição da aplicação NestJS

O projeto foi desenvolvido como parte do curso **FIAP SOAT - Fase 3**, com foco em:
- Arquitetura de microsserviços
- Clean Architecture
- CI/CD automatizado
- Otimização de custos para AWS Academy ($50 USD budget)

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AWS Cloud (us-east-1)                         │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  API Gateway (REST API)                                        │  │
│  │  ├─ POST /signup  → Lambda fastfoodSignup                     │  │
│  │  └─ POST /auth    → Lambda fastfoodAuth                       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                          ↓                                          │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  AWS Cognito User Pool (fastfood-users)                       │  │
│  │  └─ Custom Attribute: CPF                                     │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                          ↓                                          │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Network Load Balancer (NLB)                                  │  │
│  │  └─ Port 80 → EKS Service (fiap-soat-application-service)    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                          ↓                                          │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  EKS Cluster (fiap-soat-eks-dev) - Kubernetes 1.30           │  │
│  │  ├─ Namespace: fiap-soat-app                                  │  │
│  │  ├─ Deployment: fiap-soat-application                         │  │
│  │  │  ├─ HPA: 1-3 replicas (CPU 70%, Memory 80%)              │  │
│  │  │  ├─ Health Checks: /health (liveness + readiness)        │  │
│  │  │  └─ Resources: 512Mi RAM / 500m CPU                       │  │
│  │  ├─ Service: fiap-soat-application-service (LoadBalancer)    │  │
│  │  ├─ ConfigMap: fiap-soat-application-config                  │  │
│  │  └─ Secret: fiap-soat-application-secrets                    │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                          ↓                                          │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  RDS PostgreSQL 17.4 (fiap-soat-db)                          │  │
│  │  ├─ Instância: db.t3.micro                                    │  │
│  │  ├─ Storage: 20 GB gp3                                        │  │
│  │  └─ VPC: vpc-0b339aae01a928665                               │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  VPC & Networking (Auto-discovered via RDS)                   │  │
│  │  ├─ 6 Subnets (3 públicas, 3 privadas)                       │  │
│  │  ├─ Security Groups (EKS Cluster + Nodes + RDS)              │  │
│  │  └─ IAM Roles: LabEksClusterRole, LabEksNodeRole             │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Fluxo de Autenticação

1. Cliente → **API Gateway** (`/signup` ou `/auth`)
2. **Lambda** processa requisição
3. **Lambda** cria/valida usuário no **NestJS** via **Load Balancer**
4. **NestJS** persiste dados no **RDS PostgreSQL**
5. **Lambda** cria/valida usuário no **Cognito**
6. **Lambda** gera **JWT token** e retorna ao cliente

---

## 🛠️ Stack Tecnológica

### Infraestrutura
- **Terraform** (v1.0+) - Infrastructure as Code
- **AWS EKS** (v1.30) - Kubernetes gerenciado
- **AWS RDS** (PostgreSQL 17.4) - Banco de dados relacional
- **AWS Lambda** (Node.js 20.x) - Funções serverless
- **AWS API Gateway** - REST API
- **AWS Cognito** - Gerenciamento de identidades
- **AWS NLB** - Network Load Balancer

### Aplicação
- **NestJS** - Framework Node.js com Clean Architecture
- **TypeScript** - Linguagem principal
- **Docker** - Containerização
- **Kubernetes** - Orquestração de containers

### DevOps
- **GitHub Actions** - CI/CD
- **kubectl** - CLI do Kubernetes
- **AWS CLI** - CLI da AWS
- **Artillery & K6** - Testes de carga

---

## 📦 Pré-requisitos

### Ferramentas Necessárias

```bash
# Terraform (>= 1.0)
terraform version

# kubectl
kubectl version --client

# AWS CLI
aws --version

# Git
git --version
```

### Conta AWS
- **AWS Academy Learner Lab** ativo
- **Budget**: $50 USD
- **Região**: us-east-1
- **Credenciais**: Renovar a cada ~3 horas

---

## 🚀 Como Deployar

### 1️⃣ Clonar o Repositório

```bash
git clone https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform.git
cd fiap-soat-k8s-terraform
```

### 2️⃣ Configurar Credenciais AWS Academy

Configure suas credenciais AWS Academy manualmente ou crie um script auxiliar:

```bash
# Abra o arquivo de credenciais
nano ~/.aws/credentials
```

Cole as credenciais do AWS Academy no formato:

```ini
[default]
aws_access_key_id=ASIAUCQMSWOI2CB3BP3S
aws_secret_access_key=ey3nbFY1QZeN57JZC3n0QlGq733TW/bv7fnpSxBr
aws_session_token=IQoJb3JpZ2luX2VjEDgaC...
```

Salve com `Ctrl+O` e saia com `Ctrl+X`.

> **Nota**: As credenciais AWS Academy expiram a cada ~3 horas. Renove-as sempre que necessário.

### 3️⃣ Configurar Variáveis do Terraform

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` se necessário (valores padrão já estão otimizados).

### 4️⃣ Provisionar Infraestrutura EKS

```bash
# Inicializar Terraform
terraform init

# Visualizar plano de execução
terraform plan

# Aplicar configuração (⚠️ Cuidado com custos!)
terraform apply
```

Aguarde ~10-15 minutos para o cluster EKS ficar pronto.

### 5️⃣ Configurar kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name fiap-soat-eks-dev
kubectl get nodes
```

### 6️⃣ Deployar Aplicação NestJS

O deployment da aplicação NestJS é gerenciado pelo **repositório [fiap-soat-application](https://github.com/3-fase-fiap-soat-team/fiap-soat-application)** via GitHub Actions.

Este repositório (`fiap-soat-k8s-terraform`) gerencia apenas a **infraestrutura Kubernetes**:
- Namespace
- ConfigMap
- Secret (via GitHub Secrets)
- Service (LoadBalancer/NLB)
- HPA (Horizontal Pod Autoscaler)

**Para deployar a aplicação:**
1. Configure os secrets no repositório `fiap-soat-application`:
   - `DB_PASSWORD`
   - `JWT_SECRET`
2. Faça push para a branch `main` do repositório da aplicação
3. O workflow CI/CD automaticamente:
   - Builda a imagem Docker
   - Faz push para ECR
   - Aplica o `deployment.yaml` no cluster EKS

Verifique o deploy:

```bash
kubectl get pods -n fiap-soat-app
kubectl get service -n fiap-soat-app
```

Aguarde ~3 minutos para o Load Balancer ficar pronto.

### 7️⃣ Testar a Aplicação

```bash
# Obter endpoint do Load Balancer
export LB_URL=$(kubectl get service -n fiap-soat-app fiap-soat-application-service \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Testar health check
curl http://$LB_URL/health

# Swagger UI (Documentação Interativa)
echo "http://$LB_URL/docs"

# Testar endpoint de produtos
curl http://$LB_URL/products
```

### 8️⃣ Deployar Infraestrutura Kubernetes via GitHub Actions

Este repositório usa **GitHub Actions** para automatizar o deploy da infraestrutura Kubernetes:

**Workflow**: `.github/workflows/deploy-eks-infra.yml`
- **Trigger**: Push na branch `main`
- **Responsabilidades**:
  - Aplica `namespace.yaml`
  - Cria `configmap.yaml` com variáveis de ambiente
  - Cria `secret.yaml` dinamicamente a partir de GitHub Secrets
  - Aplica `service.yaml` (LoadBalancer/NLB)
  - Aplica `hpa.yaml` (Horizontal Pod Autoscaler)

**Configurar Secrets no GitHub**:
1. Acesse: `Settings` > `Secrets and variables` > `Actions`
2. Adicione os secrets:
   - `DB_PASSWORD`: Senha do RDS PostgreSQL
   - `JWT_SECRET`: Secret para geração de tokens JWT

**Deploy Manual (Opcional)**:
```bash
# Aplicar manualmente os manifestos
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/secret.yaml  # ⚠️ Configure antes!
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/hpa.yaml
```

> **Importante**: O `deployment.yaml` é gerenciado pelo repositório da aplicação (`fiap-soat-application`), não por este repositório.

---

### 9️⃣ (Opcional) Deployar Lambda + Cognito

Consulte o repositório [fiap-soat-lambda](https://github.com/3-fase-fiap-soat-team/fiap-soat-lambda) branch `feat-rafael`.

---

## 🧪 Guia Completo de Testes

### ⚙️ Funcionalidades de Alta Disponibilidade

Este projeto implementa **Horizontal Pod Autoscaler (HPA)** e **Health Checks** para garantir alta disponibilidade:

#### Horizontal Pod Autoscaler (HPA)
- **Replicas**: 1 mínimo, 3 máximo
- **Métricas**: CPU 70%, Memory 80%
- **Comportamento**: Escala automaticamente baseado na carga
```bash
# Monitorar HPA em tempo real
kubectl get hpa -n fiap-soat-app -w

# Simular carga e observar autoscaling
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://fiap-soat-application-service/products; done"
```

#### Health Checks
- **Liveness Probe**: GET /health (porta 3000) - verifica se pod está vivo
- **Readiness Probe**: GET /health (porta 3000) - verifica se pod está pronto para receber tráfego
- **Configuração**: 
  - Delay inicial: 30s (liveness), 10s (readiness)
  - Período: 10s
  - Timeout: 5s
  - Falhas permitidas: 3

```bash
# Verificar health checks
kubectl describe pod -n fiap-soat-app -l app=fiap-soat-application | grep -A 10 "Liveness\|Readiness"

# Testar endpoint diretamente
curl http://$LB_URL/health
```

### 🧪 Testes Funcionais

Para testes mais detalhados (fluxo de autenticação, pedidos, testes de carga), consulte os **load-tests/** no repositório.

### Quick Test: Fluxo Completo

```bash
# 1. Health Check
curl http://$LB_URL/health

# 2. Cadastrar cliente (API Gateway + Lambda)
export API_URL="https://nlxpeaq6w0.execute-api.us-east-1.amazonaws.com/dev"
curl -X POST $API_URL/signup \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678900","name":"João Silva","email":"joao@test.com"}'

# 3. Autenticar
curl -X POST $API_URL/auth \
  -H "Content-Type: application/json" \
  -d '{"cpf":"12345678900"}'

# 4. Consultar produtos
curl http://$LB_URL/products

# 5. Monitorar HPA
kubectl get hpa -n fiap-soat-app -w
```

---

## 📁 Estrutura do Repositório

```
fiap-soat-k8s-terraform/
├── .github/
│   └── workflows/
│       └── deploy-eks-infra.yml # CI/CD: Deploy infra K8s (ConfigMap, Secret, Service, HPA)
│
├── environments/
│   └── dev/
│       ├── main.tf              # Configuração principal
│       ├── variables.tf         # Variáveis de entrada
│       ├── outputs.tf           # Outputs (cluster endpoint, etc)
│       └── terraform.tfvars     # Valores das variáveis
│
├── modules/
│   └── eks/
│       ├── cluster.tf           # Cluster EKS + IAM roles
│       ├── variables.tf         # Variáveis do módulo
│       └── outputs.tf           # Outputs do módulo
│
├── manifests/
│   ├── namespace.yaml           # Namespace fiap-soat-app
│   ├── configmap.yaml           # fiap-soat-application-config
│   ├── secret.example.yaml      # Template de secrets (⚠️ NÃO commitar secret.yaml!)
│   ├── deployment.yaml          # fiap-soat-application (gerenciado pelo repo da aplicação)
│   ├── service.yaml             # fiap-soat-application-service (LoadBalancer/NLB)
│   └── hpa.yaml                 # Horizontal Pod Autoscaler (1-3 replicas, CPU 70%, Memory 80%)
│
├── load-tests/
│   ├── artillery/               # Testes de carga Artillery
│   └── k6/                      # Testes de carga K6
│
├── .gitignore                   # Ignora: scripts/, docs/, secrets
└── README.md                    # Este arquivo
```

> **Nota**: As pastas `scripts/` e `docs/` foram removidas do controle de versão para simplificar o repositório. Apenas os manifestos Kubernetes e configurações Terraform são versionados.

---

## 💻 Comandos Úteis

### Kubernetes

```bash
# Listar todos os recursos no namespace
kubectl get all -n fiap-soat-app

# Ver logs da aplicação
kubectl logs -n fiap-soat-app -l app=fiap-soat-application -f

# Descrever pod (troubleshooting)
kubectl describe pod -n fiap-soat-app <pod-name>

# Port-forward para testes locais
kubectl port-forward -n fiap-soat-app service/fiap-soat-application-service 3000:80

# Ver status do HPA (autoscaling)
kubectl get hpa -n fiap-soat-app

# Reiniciar deployment
kubectl rollout restart deployment -n fiap-soat-app fiap-soat-application
```

### Terraform

```bash
# Ver estado atual
terraform show

# Ver outputs
terraform output

# Destruir infraestrutura (⚠️ CUIDADO)
terraform destroy

# Formatar código
terraform fmt -recursive

# Validar configuração
terraform validate
```

### AWS CLI

```bash
# Verificar cluster EKS
aws eks describe-cluster --name fiap-soat-eks-dev --region us-east-1

# Listar nodes
aws eks list-nodegroups --cluster-name fiap-soat-eks-dev --region us-east-1

# Verificar RDS
aws rds describe-db-instances --query 'DBInstances[0].Endpoint'
```

### Testes de Carga

```bash
# Artillery (smoke test)
cd load-tests/artillery
artillery run smoke-test.yml

# K6 (stress test)
cd load-tests/k6
k6 run stress-test.js
```

---

## 🌿 Branches e Repositórios

### Repositório Principal (EKS/Terraform)
- **Repo**: [fiap-soat-k8s-terraform](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform)
- **Branch Principal**: `main`
- **Responsável**: rs94458 (Dev 3)
- **Conteúdo**: Infraestrutura EKS, Terraform, Kubernetes manifests

### Repositório Lambda (Autenticação Serverless)
- **Repo**: [fiap-soat-lambda](https://github.com/3-fase-fiap-soat-team/fiap-soat-lambda)
- **Branch Funcional**: `feat-rafael` ✅ **Deployado e testado**
- **Branch Original**: `feat/lambda-e-cognito`
- **Responsável**: rs94458 (Dev 3)
- **Conteúdo**: Lambda Functions (signup, auth), API Gateway, Cognito

### Repositório Aplicação (NestJS)
- **Repo**: [fiap-soat-application](https://github.com/3-fase-fiap-soat-team/fiap-soat-application)
- **Branch Principal**: `main`
- **Arquitetura**: Clean Architecture + Domain-Driven Design
- **Conteúdo**: Aplicação NestJS com endpoints de produtos, clientes, pedidos

---

## 💰 Otimização de Custos (AWS Academy)

### Recursos Ativos
- **EKS Control Plane**: ~$73/mês
- **RDS db.t3.micro**: ~$15.50/mês
- **Network Load Balancer**: ~$22/mês
- **EC2 t3.micro (2 nodes)**: ~$15/mês
- **Total Estimado**: ~$125.50/mês ⚠️ *Excede budget de $50*

### Recomendações
- ✅ **Sempre destruir recursos quando não estiver usando**
- ✅ **Usar apenas 1 node** (`node_group_desired_size = 1`)
- ✅ **Desabilitar cluster fora do horário de desenvolvimento**
- ⚠️ **EKS Control Plane é o maior custo** ($2.40/dia)

```bash
# Destruir tudo para economizar
cd environments/dev
terraform destroy --auto-approve
```

---

## 👥 Equipe

**Projeto**: FIAP SOAT - Fase 3  
**Organização**: [3-fase-fiap-soat-team](https://github.com/3-fase-fiap-soat-team)  
**Responsável Infraestrutura**: rs94458 (Dev 3)

### Repositórios do Projeto
- 🏗️ [fiap-soat-k8s-terraform](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform) - Infraestrutura EKS
- 🔐 [fiap-soat-lambda](https://github.com/3-fase-fiap-soat-team/fiap-soat-lambda) - Autenticação Serverless
- 🍔 [fiap-soat-application](https://github.com/3-fase-fiap-soat-team/fiap-soat-application) - Aplicação NestJS

---

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique os logs dos pods: `kubectl logs -n fiap-soat-app -l app=fiap-soat-application`
2. Consulte a documentação do Kubernetes: https://kubernetes.io/docs/
3. Abra uma [issue no GitHub](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/issues)

---

## 📝 Licença

Este projeto é parte do curso **FIAP SOAT - Arquitetura de Software**.  
Desenvolvido para fins acadêmicos.

---

**🎓 Otimizado para AWS Academy** | **🚀 Pronto para Produção** | **📊 Econômico**

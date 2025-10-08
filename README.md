# 🚀 FIAP SOAT - Sistema de Fast Food

**Infraestrutura como Código para Kubernetes na AWS**

[![Deploy EKS](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/actions/workflows/deploy-app.yml/badge.svg?branch=main)](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/actions/workflows/deploy-app.yml)
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
│  │  ├─ Deployment: fiap-soat-application (HPA: 1-3 replicas)    │  │
│  │  ├─ Service: LoadBalancer tipo NLB                            │  │
│  │  └─ ConfigMap + Secrets                                       │  │
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

```bash
./scripts/aws-config.sh
```

Cole as credenciais do AWS Academy quando solicitado no formato:

```
aws_access_key_id=ASIAUCQMSWOI2CB3BP3S
aws_secret_access_key=ey3nbFY1QZeN57JZC3n0QlGq733TW/bv7fnpSxBr
aws_session_token=IQoJb3JpZ2luX2VjEDgaC...
```

Pressione `Ctrl+D` para finalizar.

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

```bash
cd ../../
kubectl apply -f manifests/
```

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

### 8️⃣ (Opcional) Deployar Lambda + Cognito

Consulte o repositório [fiap-soat-lambda](https://github.com/3-fase-fiap-soat-team/fiap-soat-lambda) branch `feat-rafael`.

---

## 🧪 Guia Completo de Testes

Para testes mais detalhados (fluxo de autenticação, pedidos, testes de carga, HPA), consulte:
- **[📖 Guia Completo de Testes](docs/TESTING-GUIDE.md)** - Passo-a-passo detalhado
- **[🔄 Estratégia CI/CD](docs/CI-CD-SEPARATION.md)** - Separação de responsabilidades
- **[🔐 Gerenciamento de Secrets](docs/SECRETS-MANAGEMENT.md)** - Como gerenciar credenciais

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
│   ├── configmap.yaml           # Configurações da aplicação
│   ├── secret.example.yaml      # Template de secrets (não commitar secret.yaml!)
│   ├── deployment.yaml          # Deploy NestJS (gerenciado pelo repo da aplicação)
│   ├── service.yaml             # Service LoadBalancer (NLB)
│   └── hpa.yaml                 # Horizontal Pod Autoscaler (1-3 replicas)
│
├── scripts/
│   ├── aws-config.sh            # Configurar credenciais AWS
│   ├── deploy.sh                # Deploy automatizado
│   ├── deploy-from-ecr.sh       # Deploy de imagem ECR
│   └── force-destroy.sh         # Destruir recursos
│
├── load-tests/
│   ├── artillery/               # Testes de carga Artillery
│   └── k6/                      # Testes de carga K6
│
├── docs/                        # Documentação técnica detalhada
│
└── README.md                    # Este arquivo
```

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

# Renovar credenciais (a cada ~3h)
./scripts/aws-config.sh
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
1. Consulte a [documentação detalhada](docs/)
2. Verifique [AWS Academy Setup Guide](docs/AWS-ACADEMY-SETUP.md)
3. Abra uma [issue no GitHub](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/issues)

---

## 📝 Licença

Este projeto é parte do curso **FIAP SOAT - Arquitetura de Software**.  
Desenvolvido para fins acadêmicos.

---

**🎓 Otimizado para AWS Academy** | **🚀 Pronto para Produção** | **📊 Econômico**

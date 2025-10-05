# 🚀 FIAP SOAT - EKS Kubernetes Infrastructure# 🚀 FIAP SOAT - EKS Kubernetes Terraform



Infraestrutura como Código (IaC) para provisionamento de cluster EKS na AWS usando Terraform, otimizado para AWS Academy.## 📊 Status: ✅ PRONTO PARA PRODUÇÃO



## 📋 Índice**Data de Update**: 30 de Setembro de 2025  

**Branch**: feature/networking-vpc  

- [Sobre o Projeto](#sobre-o-projeto)**Aplicação NestJS**: ✅ Funcionando no EKS

- [Arquitetura](#arquitetura)

- [Pré-requisitos](#pré-requisitos)---

- [Quick Start](#quick-start)

- [Estrutura do Projeto](#estrutura-do-projeto)## 🎯 **O que funciona AGORA**

- [Documentação](#documentação)

- [Scripts Úteis](#scripts-úteis)### ✅ Infraestrutura EKS

- [CI/CD](#cicd)- **Cluster EKS**: v1.28 funcional

- [Troubleshooting](#troubleshooting)- **Worker Nodes**: t3.small (1 node)

- **Networking**: VPC + Subnets + Security Groups

## 🎯 Sobre o Projeto- **LoadBalancer**: AWS ELB automático



Este repositório contém a infraestrutura Terraform para provisionamento de um cluster Amazon EKS (Elastic Kubernetes Service) otimizado para AWS Academy, com as seguintes características:### ✅ Aplicação NestJS 

- **Imagem ECR**: Uploadada e funcionando

- **Auto-discovery** de VPC, IAM Roles e Subnets via RDS existente- **Deployment**: Limpo e organizado

- **Security Groups** configuráveis (criar novos ou reutilizar existentes)- **Service**: LoadBalancer expondo porta 80→3000

- **GitHub Actions** para CI/CD automatizado- **Health Checks**: Endpoints `/` e `/health`

- **AWS Academy compliant** - funciona com limitações do AWS Academy Learner Lab- ✅ **Budget Optimization:** Configurado para $50 USD

- **Cost-optimized** - configuração econômica com t3.micro nodes- ✅ **Scripts de teste:** Prontos e funcionando

- ✅ **Aplicação:** Manifests prontos para deploy

### ✨ Funcionalidades

## 👨‍💻 **Responsável**

- ✅ Auto-discovery de VPC e Subnets através de RDS existente- **Dev 3 (rs94458)** - EKS + Infraestrutura de Integração com App

- ✅ Auto-discovery de IAM Roles (LabEksClusterRole, LabEksNodeRole)- **Repositórios:** `fiap-soat-k8s-terraform`

- ✅ Security Groups flexíveis (criação automática ou reutilização)- **Foco:** Cluster EKS + Deploy da aplicação

- ✅ EKS Cluster v1.27 com 3 add-ons essenciais- **Tecnologias:** Terraform, AWS EKS, Kubernetes, Docker, CI/CD

- ✅ Node Groups configuráveis (min/max/desired size)

- ✅ IRSA (IAM Roles for Service Accounts) habilitado## 📁 **Estrutura do Projeto**

- ✅ Scripts de deploy e manutenção automatizados```

- ✅ Testes de carga com Artillery e K6environments/

├── dev/               # Ambiente desenvolvimento

## 🏗️ Arquitetura│   ├── main.tf        # Configuração principal EKS

│   ├── variables.tf   # Variáveis do ambiente

```│   ├── outputs.tf     # Outputs (cluster endpoint, etc)

┌─────────────────────────────────────────────────────────────┐│   └── backend.tf     # Backend S3 para state

│                       AWS Academy Account                    │├── prod/              # Ambiente produção (futuro)

├─────────────────────────────────────────────────────────────┤modules/

│                                                              │├── eks/               # Módulo EKS principal

│  ┌──────────────────────────────────────────────────────┐  ││   ├── cluster.tf     # Cluster EKS

│  │  VPC (descoberta via RDS)                            │  ││   ├── node-groups.tf # Node groups

│  │  ├─ 6 Subnets (públicas/privadas)                    │  ││   ├── addons.tf      # Add-ons essenciais

│  │  ├─ Security Groups (EKS Cluster + Nodes)            │  ││   └── outputs.tf     # Outputs do módulo

│  │  └─ RDS PostgreSQL 17.4                              │  │├── networking/        # VPC e networking

│  └──────────────────────────────────────────────────────┘  ││   ├── vpc.tf         # VPC para EKS

│                                                              ││   ├── subnets.tf     # Subnets públicas/privadas

│  ┌──────────────────────────────────────────────────────┐  ││   └── security.tf    # Security groups

│  │  EKS Cluster (fiap-soat-eks-dev)                     │  │├── monitoring/        # Observabilidade básica

│  │  ├─ Version: 1.27                                     │  │manifests/

│  │  ├─ IAM: LabEksClusterRole (auto-discovered)         │  │├── application/       # Manifests K8s da aplicação

│  │  ├─ Add-ons: vpc-cni, kube-proxy, coredns            │  │├── ingress/           # Configuração Ingress

│  │  └─ OIDC Provider (IRSA enabled)                     │  │└── secrets/           # Secrets Kubernetes

│  └──────────────────────────────────────────────────────┘  │```

│                                                              │

│  ┌──────────────────────────────────────────────────────┐  │## ⚙️ **Configuração AWS Academy** 🎓

│  │  Node Group (general)                                 │  │- **Região:** us-east-1

│  │  ├─ Instance Type: t3.micro                           │  │- **Budget:** $50 USD (AWS Academy Learner Lab)

│  │  ├─ Capacity: ON_DEMAND                               │  │- **IAM Roles:** Usa roles pré-criadas do Academy (`LabEksClusterRole`, `LabEksNodeRole`)

│  │  ├─ Min: 1 | Max: 3 | Desired: 2                     │  │- **Node Group:** 1x t3.micro (mais econômico permitido)

│  │  └─ IAM: LabEksNodeRole (auto-discovered)            │  │- **Networking:** Subnets públicas (sem NAT Gateway para economia)

│  └──────────────────────────────────────────────────────┘  │- **Add-ons:** Apenas essenciais (kube-proxy, vpc-cni, coredns)

│                                                              │- **Load Balancer:** NodePort/ClusterIP (sem ELB para economia)

└─────────────────────────────────────────────────────────────┘

```## 🚀 **Quick Start - AWS Academy** ⚡



## 📦 Pré-requisitos### **1. Clone e Configure (2 minutos)**

```bash

- **Terraform** >= 1.0git clone https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform.git

- **AWS CLI** configurado com credenciais AWS Academycd fiap-soat-k8s-terraform

- **kubectl** para interagir com o cluster

- **Git** para controle de versão# Configurar credenciais AWS Academy (cole o conteúdo do lab)

- **AWS Account** - AWS Academy Learner Lab ativo./scripts/aws-config.sh

```

### Credenciais AWS Academy

### **2. Teste Rápido (5 minutos)**

As credenciais AWS Academy expiram a cada ~3 horas. Use o script de renovação:```bash

# Teste rápido e seguro com timeout automático

```bash./scripts/test-eks-safe.sh

./scripts/aws-config.sh```

# Cole as credenciais e pressione Ctrl+D

```### **3. Deploy da Aplicação**

```bash

## 🚀 Quick Start# Configurar kubectl

aws eks update-kubeconfig --region us-east-1 --name fiap-soat-cluster

### 1. Clone o repositório

# Deploy da aplicação

```bashkubectl apply -f manifests/application/

git clone https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform.git

cd fiap-soat-k8s-terraform# Verificar

```kubectl get pods

kubectl get services

### 2. Configure credenciais AWS```



```bash## 🚀 **Setup Local**

./scripts/aws-config.sh

# Cole as credenciais AWS Academy quando solicitado### **Opção 1: Setup Automatizado (Recomendado)**

``````bash

# Clonar repositório

### 3. Configure variáveisgit clone https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform.git

cd fiap-soat-k8s-terraform

```bash

cd environments/dev# Setup completo automatizado

cp terraform.tfvars.example terraform.tfvars./scripts/setup-dev.sh

# Edite terraform.tfvars se necessário```

```

### **Opção 2: Setup Manual**

### 4. Deploy```bash

# Configurar Git

```bashgit config user.name "rs94458"

# Inicializar Terraformgit config user.email "seu-email@gmail.com"

terraform init

# Instalar dependências

# Planejar alterações# Terraform

terraform plansudo apt-get install terraform



# Aplicar configuração# kubectl

terraform applycurl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

```sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl



### 5. Configure kubectl# AWS CLI (se necessário)

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

```bashunzip awscliv2.zip && sudo ./aws/install

aws eks update-kubeconfig --region us-east-1 --name fiap-soat-eks-dev

kubectl get nodes# Verificar instalações

```terraform version

kubectl version --client

## 📁 Estrutura do Projetoaws --version

```

```

fiap-soat-k8s-terraform/## 🔑 **Configuração AWS Academy**

├── environments/

│   └── dev/              # Configuração do ambiente de desenvolvimento### **Script de Configuração Rápida**

│       ├── main.tf       # Configuração principal (VPC discovery via RDS)```bash

│       ├── variables.tf  # Variáveis do ambiente# Execute o script e cole as credenciais do AWS Academy

│       ├── outputs.tf    # Outputs do Terraform./scripts/aws-config.sh

│       └── terraform.tfvars  # Valores das variáveis

├── modules/# Cole o conteúdo completo no formato:

│   ├── eks/              # Módulo do EKS Cluster# aws_access_key_id=ASIAUCQMSWOI2CB3BP3S

│   │   ├── cluster.tf    # Cluster + Security Groups + IAM discovery# aws_secret_access_key=ey3nbFY1QZeN57JZC3n0QlGq733TW/bv7fnpSxBr

│   │   ├── node_groups.tf# aws_session_token=IQoJb3JpZ2luX2VjEDgaC...

│   │   ├── oidc.tf# 

│   │   ├── addons.tf# Pressione Ctrl+D para finalizar

│   │   ├── variables.tf# O script configura automaticamente e testa a conexão

│   │   └── outputs.tf```

│   └── vpc/              # Módulo VPC (não usado - usamos VPC do RDS)

├── manifests/            # Kubernetes manifests### **Verificação**

│   ├── namespace.yaml```bash

│   ├── deployment.yaml# Testar se as credenciais estão funcionando

│   └── service.yamlaws sts get-caller-identity

├── scripts/              # Scripts auxiliares```

│   ├── aws-config.sh     # Renovar credenciais AWS Academy

│   ├── deploy.sh         # Deploy completo automatizado## 🏗️ **Desenvolvimento**

│   ├── deploy-from-ecr.sh```bash

│   ├── force-destroy.sh# Inicializar Terraform

│   └── README.mdcd environments/dev

├── load-tests/           # Testes de cargaterraform init

│   ├── artillery/

│   └── k6/# Planejar criação do cluster

├── docs/                 # Documentação organizadaterraform plan

│   ├── guides/           # Guias de configuração

│   ├── troubleshooting/  # Soluções de problemas# Aplicar mudanças (⚠️ CUIDADO COM CUSTOS!)

│   ├── analysis/         # Análises técnicasterraform apply

│   └── archived/         # Documentação histórica

├── .github/# Configurar kubectl

│   └── workflows/aws eks update-kubeconfig --region us-east-1 --name fiap-soat-cluster

│       └── terraform-eks.yml  # CI/CD pipeline

└── README.md             # Este arquivo# Verificar cluster

```kubectl get nodes

kubectl get pods -A

## 📚 Documentação

# Deploy da aplicação

### Guiaskubectl apply -f ../../manifests/application/



- [IAM Roles Auto-Discovery](docs/guides/IAM-ROLES-AUTO-DISCOVERY.md) - Como funciona a descoberta automática de roles# Verificar deploy

- [Security Groups Guide](docs/guides/SECURITY-GROUPS-GUIDE.md) - Configuração de Security Groupskubectl get pods

- [VPC Discovery via RDS](docs/guides/VPC-DISCOVERY-CONFIRMATION.md) - Como descobrir VPC através do RDSkubectl get services

- [ECR Upload Guide](docs/guides/ECR-UPLOAD-GUIDE.md) - Subir imagens para ECR```

- [Deploy Script](docs/guides/DEPLOY-SCRIPT-ENHANCED.md) - Uso do script de deploy

## 💰 **Otimizações de Custo AWS Academy**

### Troubleshooting```hcl

# Configurações ultra-econômicas

- [Problemas Resolvidos](docs/troubleshooting/PROBLEMA-RESOLVIDO.md)node_group_instance_types = ["t3.micro"]    # Mais barato

- [Situações de Emergência](docs/troubleshooting/SITUACAO-EMERGENCIAL.md)node_group_desired_size   = 1               # Mínimo

- [VPC Orphan Analysis](docs/troubleshooting/VPC-ORPHAN-ANALYSIS.md)node_group_max_size      = 2               # Limite baixo

node_group_min_size      = 1               # Mínimo

### Análises Técnicas

# Sem add-ons pagos

- [Terraform State Analysis](docs/analysis/TERRAFORM-STATE-ANALYSIS.md)cluster_addons = {

- [Project Context Complete](docs/analysis/PROJECT-CONTEXT-COMPLETE.md)  kube-proxy = {}     # Gratuito

  vpc-cni    = {}     # Gratuito  

## 🔧 Scripts Úteis  coredns    = {}     # Gratuito

  # aws-load-balancer-controller = {} # DESABILITADO (custa $)

### Renovar Credenciais AWS Academy}



```bash# Networking básico

./scripts/aws-config.shenable_nat_gateway = false      # Economia (usar só subnets públicas)

```single_nat_gateway = true       # Se precisar de NAT

```

### Deploy Completo Automatizado

## 🔄 **Workflow de Desenvolvimento**

```bash1. **Branch:** `feature/[nome-da-feature]`

./scripts/deploy.sh2. **Desenvolvimento:** Modificar Terraform + manifests K8s

```3. **Teste:** `terraform plan` + validação manifests

4. **PR:** Solicitar review do team

### Deploy de Aplicação do ECR5. **CI/CD:** GitHub Actions valida Terraform

6. **Deploy:** Manual para cluster (cuidado com custos)

```bash

./scripts/deploy-from-ecr.sh## 🧪 **CI/CD Pipeline**

```- **Trigger:** Push na `main` ou PR

- **Validação:** `terraform validate` + `kubectl --dry-run`

### Destruir Recursos com Força- **Linting:** `tflint` + `kubeval`

- **Plan:** `terraform plan` (comentário no PR)

```bash- **Deploy:** Manual após aprovação

./scripts/force-destroy.sh

```## ☸️ **Recursos Kubernetes**

```yaml

Veja mais detalhes em [scripts/README.md](scripts/README.md).# Exemplo de deploy da aplicação

apiVersion: apps/v1

## 🔄 CI/CDkind: Deployment

metadata:

O projeto usa **GitHub Actions** para automação de deploy. O workflow é acionado em:  name: fiap-soat-app

spec:

- Pull Requests para `main`  replicas: 1  # Mínimo para economia

- Push direto na branch `main`  selector:

    matchLabels:

**Arquivo:** `.github/workflows/terraform-eks.yml`      app: fiap-soat-app

  template:

### Secrets Necessários    spec:

      containers:

Configure no GitHub Repository Settings > Secrets:      - name: app

        image: fiap-soat-app:latest

- `AWS_ACCESS_KEY_ID`        ports:

- `AWS_SECRET_ACCESS_KEY`        - containerPort: 3000

- `AWS_SESSION_TOKEN`        resources:

          limits:

## 🐛 Troubleshooting            memory: "256Mi"    # Limitado para t3.micro

            cpu: "200m"

### Credenciais Expiradas          requests:

            memory: "128Mi"

**Erro:** `AuthFailure: AWS was not able to validate the provided access credentials`            cpu: "100m"

```

**Solução:**

```bash## 🔐 **Integração com Outros Repositórios**

./scripts/aws-config.sh- **Database:** Conecta com RDS via service/endpoint

# Cole novas credenciais do AWS Academy- **Lambda:** Integração via API Gateway

```- **Application:** Deploy da aplicação NestJS no cluster



### Não Consegue Acessar EC2 VPCs## 🔐 **Secrets GitHub (Auto-configurados)**

- `AWS_ACCESS_KEY_ID` - Chave de acesso AWS Academy

**Problema:** AWS Academy `voclabs` role não tem permissão `ec2:DescribeVpcs`- `AWS_SECRET_ACCESS_KEY` - Secret de acesso AWS Academy

- `AWS_SESSION_TOKEN` - Token de sessão AWS Academy

**Solução:** O projeto usa **auto-discovery via RDS** para contornar essa limitação.- `TF_STATE_BUCKET` - Bucket S3 para state

- `TF_STATE_LOCK_TABLE` - DynamoDB para locks

### EKS Cluster Não Sobe

## 📋 **Comandos Úteis**

**Erro:** `couldn't find resource` para IAM roles```bash

# Verificar estado do cluster

**Solução:** O projeto usa **auto-discovery de IAM roles** - roles são descobertos dinamicamente.kubectl cluster-info

kubectl get nodes -o wide

### Security Groups Incompatíveis

# Verificar pods da aplicação

**Problema:** Tentativa de reutilizar SGs do RDS para EKSkubectl get pods -l app=fiap-soat-app



**Solução:** Configure `create_security_groups = true` no `terraform.tfvars` para criar SGs específicos para EKS.# Logs da aplicação

kubectl logs -l app=fiap-soat-app -f

## 🤝 Contribuindo

# Port-forward para testes locais

1. Fork o projetokubectl port-forward service/fiap-soat-app 3000:3000

2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)

3. Commit suas mudanças (`git commit -m 'feat: adiciona nova feature'`)# Escalar aplicação (se necessário)

4. Push para a branch (`git push origin feature/nova-feature`)kubectl scale deployment fiap-soat-app --replicas=2

5. Abra um Pull Request

# Destruir cluster (IMPORTANTE para economia)

## 📝 Licençaterraform destroy

```

Este projeto é parte do curso FIAP SOAT - Fase 3.

## 📚 **Links Importantes**

## 👥 Equipe- **Organização:** https://github.com/3-fase-fiap-soat-team

- **Application Repo:** https://github.com/3-fase-fiap-soat-team/fiap-soat-application

- **Owner:** rs94458- **EKS Docs:** https://docs.aws.amazon.com/eks/

- **Team:** 3-fase-fiap-soat-team- **Kubernetes Docs:** https://kubernetes.io/docs/

- **Project:** fiap-soat-fase3

## ⚠️ **IMPORTANTE - AWS Academy** 🎓

## 📞 Suporte- **EKS Control Plane:** ~$2.40/dia ($73/mês)

- **Worker Nodes:** ~$0.50/dia (t3.micro)

Para dúvidas ou problemas:- **Budget total:** $50 USD - Dura ~20 dias com cluster ativo

- **SEMPRE limpar:** Execute `./scripts/emergency-state-cleanup.sh` ou delete via console

1. Consulte a [documentação](docs/)- **CRÍTICO:** Delete cluster no console AWS Academy quando não estiver usando!

2. Verifique o [troubleshooting](docs/troubleshooting/)

3. Abra uma [issue](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/issues)## 🛠️ **Scripts Incluídos** 🆕

- `test-eks-safe.sh` - Teste com timeout automático e limite de custo

---- `emergency-state-cleanup.sh` - Limpeza de emergência quando AWS Academy bloqueia CLI

- `force-destroy.sh` - Múltiplas estratégias para destroy

**🎓 AWS Academy Optimized** | **🚀 Production Ready** | **📊 Cost Effective**- `monitor-cleanup.sh` - Monitora recursos ativos

- `aws-config.sh` - Configuração automática de credenciais

## 📋 **AWS Academy - Roles Pré-criadas** ✨
O AWS Academy fornece roles específicas que devem ser usadas:
```hcl
# Automaticamente detectadas pelo Terraform:
cluster_service_role = "LabEksClusterRole"    # Para o cluster EKS
node_instance_role   = "LabEksNodeRole"       # Para worker nodes
```

## 🛡️ **Segurança**
- VPC isolada com subnets privadas
- Security Groups restritivos  
- RBAC Kubernetes configurado
- Network Policies (se necessário)
- Secrets Kubernetes para credenciais
- Service Accounts com IAM roles

## 🔧 **Troubleshooting**
```bash
# Verificar logs do cluster
kubectl logs -n kube-system -l k8s-app=aws-node

# Verificar eventos
kubectl get events --sort-by='.lastTimestamp'

# Verificar resources
kubectl describe node
kubectl top pods

# Verificar EKS add-ons
aws eks describe-cluster --name fiap-soat-cluster
```

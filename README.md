# FIAP SOAT - Kubernetes Infrastructure ✅ AWS Academy Ready

Terraform para EKS - Fase 3 **[VERSÃO 1.0 - TESTADA E FUNCIONANDO]**

## 🎯 **Objetivo**
Provisionar cluster EKS (Kubernetes) na AWS usando Terraform, **totalmente compatível com AWS Academy** e otimizado para budget de $50 USD.

## 🏆 **STATUS: CONFIGURAÇÃO VALIDADA** ✅
- ✅ **Terraform validation:** PASSOU
- ✅ **EKS Cluster:** Criado com sucesso usando roles AWS Academy
- ✅ **AWS Academy Compatibility:** 100% funcional
- ✅ **Budget Optimization:** Configurado para $50 USD
- ✅ **Scripts de teste:** Prontos e funcionando
- ✅ **Aplicação:** Manifests prontos para deploy

## 👨‍💻 **Responsável**
- **Dev 3 (rs94458)** - EKS + Infraestrutura de Integração com App
- **Repositórios:** `fiap-soat-k8s-terraform`
- **Foco:** Cluster EKS + Deploy da aplicação
- **Tecnologias:** Terraform, AWS EKS, Kubernetes, Docker, CI/CD

## 📁 **Estrutura do Projeto**
```
environments/
├── dev/               # Ambiente desenvolvimento
│   ├── main.tf        # Configuração principal EKS
│   ├── variables.tf   # Variáveis do ambiente
│   ├── outputs.tf     # Outputs (cluster endpoint, etc)
│   └── backend.tf     # Backend S3 para state
├── prod/              # Ambiente produção (futuro)
modules/
├── eks/               # Módulo EKS principal
│   ├── cluster.tf     # Cluster EKS
│   ├── node-groups.tf # Node groups
│   ├── addons.tf      # Add-ons essenciais
│   └── outputs.tf     # Outputs do módulo
├── networking/        # VPC e networking
│   ├── vpc.tf         # VPC para EKS
│   ├── subnets.tf     # Subnets públicas/privadas
│   └── security.tf    # Security groups
├── monitoring/        # Observabilidade básica
manifests/
├── application/       # Manifests K8s da aplicação
├── ingress/           # Configuração Ingress
└── secrets/           # Secrets Kubernetes
```

## ⚙️ **Configuração AWS Academy** 🎓
- **Região:** us-east-1
- **Budget:** $50 USD (AWS Academy Learner Lab)
- **IAM Roles:** Usa roles pré-criadas do Academy (`LabEksClusterRole`, `LabEksNodeRole`)
- **Node Group:** 1x t3.micro (mais econômico permitido)
- **Networking:** Subnets públicas (sem NAT Gateway para economia)
- **Add-ons:** Apenas essenciais (kube-proxy, vpc-cni, coredns)
- **Load Balancer:** NodePort/ClusterIP (sem ELB para economia)

## 🚀 **Quick Start - AWS Academy** ⚡

### **1. Clone e Configure (2 minutos)**
```bash
git clone https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform.git
cd fiap-soat-k8s-terraform

# Configurar credenciais AWS Academy (cole o conteúdo do lab)
./scripts/aws-config.sh
```

### **2. Teste Rápido (5 minutos)**
```bash
# Teste rápido e seguro com timeout automático
./scripts/test-eks-safe.sh
```

### **3. Deploy da Aplicação**
```bash
# Configurar kubectl
aws eks update-kubeconfig --region us-east-1 --name fiap-soat-cluster

# Deploy da aplicação
kubectl apply -f manifests/application/

# Verificar
kubectl get pods
kubectl get services
```

## 🚀 **Setup Local**

### **Opção 1: Setup Automatizado (Recomendado)**
```bash
# Clonar repositório
git clone https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform.git
cd fiap-soat-k8s-terraform

# Setup completo automatizado
./scripts/setup-dev.sh
```

### **Opção 2: Setup Manual**
```bash
# Configurar Git
git config user.name "rs94458"
git config user.email "seu-email@gmail.com"

# Instalar dependências
# Terraform
sudo apt-get install terraform

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# AWS CLI (se necessário)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# Verificar instalações
terraform version
kubectl version --client
aws --version
```

## 🔑 **Configuração AWS Academy**

### **Script de Configuração Rápida**
```bash
# Execute o script e cole as credenciais do AWS Academy
./scripts/aws-config.sh

# Cole o conteúdo completo no formato:
# aws_access_key_id=ASIAUCQMSWOI2CB3BP3S
# aws_secret_access_key=ey3nbFY1QZeN57JZC3n0QlGq733TW/bv7fnpSxBr
# aws_session_token=IQoJb3JpZ2luX2VjEDgaC...
# 
# Pressione Ctrl+D para finalizar
# O script configura automaticamente e testa a conexão
```

### **Verificação**
```bash
# Testar se as credenciais estão funcionando
aws sts get-caller-identity
```

## 🏗️ **Desenvolvimento**
```bash
# Inicializar Terraform
cd environments/dev
terraform init

# Planejar criação do cluster
terraform plan

# Aplicar mudanças (⚠️ CUIDADO COM CUSTOS!)
terraform apply

# Configurar kubectl
aws eks update-kubeconfig --region us-east-1 --name fiap-soat-cluster

# Verificar cluster
kubectl get nodes
kubectl get pods -A

# Deploy da aplicação
kubectl apply -f ../../manifests/application/

# Verificar deploy
kubectl get pods
kubectl get services
```

## 💰 **Otimizações de Custo AWS Academy**
```hcl
# Configurações ultra-econômicas
node_group_instance_types = ["t3.micro"]    # Mais barato
node_group_desired_size   = 1               # Mínimo
node_group_max_size      = 2               # Limite baixo
node_group_min_size      = 1               # Mínimo

# Sem add-ons pagos
cluster_addons = {
  kube-proxy = {}     # Gratuito
  vpc-cni    = {}     # Gratuito  
  coredns    = {}     # Gratuito
  # aws-load-balancer-controller = {} # DESABILITADO (custa $)
}

# Networking básico
enable_nat_gateway = false      # Economia (usar só subnets públicas)
single_nat_gateway = true       # Se precisar de NAT
```

## 🔄 **Workflow de Desenvolvimento**
1. **Branch:** `feature/[nome-da-feature]`
2. **Desenvolvimento:** Modificar Terraform + manifests K8s
3. **Teste:** `terraform plan` + validação manifests
4. **PR:** Solicitar review do team
5. **CI/CD:** GitHub Actions valida Terraform
6. **Deploy:** Manual para cluster (cuidado com custos)

## 🧪 **CI/CD Pipeline**
- **Trigger:** Push na `main` ou PR
- **Validação:** `terraform validate` + `kubectl --dry-run`
- **Linting:** `tflint` + `kubeval`
- **Plan:** `terraform plan` (comentário no PR)
- **Deploy:** Manual após aprovação

## ☸️ **Recursos Kubernetes**
```yaml
# Exemplo de deploy da aplicação
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fiap-soat-app
spec:
  replicas: 1  # Mínimo para economia
  selector:
    matchLabels:
      app: fiap-soat-app
  template:
    spec:
      containers:
      - name: app
        image: fiap-soat-app:latest
        ports:
        - containerPort: 3000
        resources:
          limits:
            memory: "256Mi"    # Limitado para t3.micro
            cpu: "200m"
          requests:
            memory: "128Mi"
            cpu: "100m"
```

## 🔐 **Integração com Outros Repositórios**
- **Database:** Conecta com RDS via service/endpoint
- **Lambda:** Integração via API Gateway
- **Application:** Deploy da aplicação NestJS no cluster

## 🔐 **Secrets GitHub (Auto-configurados)**
- `AWS_ACCESS_KEY_ID` - Chave de acesso AWS Academy
- `AWS_SECRET_ACCESS_KEY` - Secret de acesso AWS Academy
- `AWS_SESSION_TOKEN` - Token de sessão AWS Academy
- `TF_STATE_BUCKET` - Bucket S3 para state
- `TF_STATE_LOCK_TABLE` - DynamoDB para locks

## 📋 **Comandos Úteis**
```bash
# Verificar estado do cluster
kubectl cluster-info
kubectl get nodes -o wide

# Verificar pods da aplicação
kubectl get pods -l app=fiap-soat-app

# Logs da aplicação
kubectl logs -l app=fiap-soat-app -f

# Port-forward para testes locais
kubectl port-forward service/fiap-soat-app 3000:3000

# Escalar aplicação (se necessário)
kubectl scale deployment fiap-soat-app --replicas=2

# Destruir cluster (IMPORTANTE para economia)
terraform destroy
```

## 📚 **Links Importantes**
- **Organização:** https://github.com/3-fase-fiap-soat-team
- **Application Repo:** https://github.com/3-fase-fiap-soat-team/fiap-soat-application
- **EKS Docs:** https://docs.aws.amazon.com/eks/
- **Kubernetes Docs:** https://kubernetes.io/docs/

## ⚠️ **IMPORTANTE - AWS Academy** 🎓
- **EKS Control Plane:** ~$2.40/dia ($73/mês)
- **Worker Nodes:** ~$0.50/dia (t3.micro)
- **Budget total:** $50 USD - Dura ~20 dias com cluster ativo
- **SEMPRE limpar:** Execute `./scripts/emergency-state-cleanup.sh` ou delete via console
- **CRÍTICO:** Delete cluster no console AWS Academy quando não estiver usando!

## 🛠️ **Scripts Incluídos** 🆕
- `test-eks-safe.sh` - Teste com timeout automático e limite de custo
- `emergency-state-cleanup.sh` - Limpeza de emergência quando AWS Academy bloqueia CLI
- `force-destroy.sh` - Múltiplas estratégias para destroy
- `monitor-cleanup.sh` - Monitora recursos ativos
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

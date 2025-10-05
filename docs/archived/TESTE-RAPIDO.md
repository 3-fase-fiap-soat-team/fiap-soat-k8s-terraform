# 🚀 **GUIA DE TESTE RÁPIDO - EKS AWS ACADEMY**

## 🎯 **Resumo das Melhorias Implementadas**

### ✅ **1. Script com Timeout Automático**
- **Arquivo**: `scripts/test-eks-safe.sh`
- **Funcionalidade**: Cria infraestrutura, testa aplicação, e **destrói automaticamente**
- **Proteção**: Timeout configurável (padrão 2h) para evitar custos excessivos
- **Monitoramento**: Alertas de tempo restante e estimativa de custos

### ✅ **2. Configuração de Subnets Corrigida**
- **Problema**: Nodes em private subnets sem NAT Gateway (sem internet)
- **Solução**: Nodes em public subnets com variável `use_public_subnets_for_nodes = true`
- **Economia**: Evita custo de NAT Gateway (~$45/mês)

### ✅ **3. Aplicação Real FIAP SOAT**
- **Substituído**: nginx:alpine placeholder
- **Novo**: Aplicação Node.js com API REST funcional
- **Endpoints**: `/health`, `/products`, `/orders`, `/`
- **Configuração**: ConfigMaps, Secrets, e Service Account

---

## 🚀 **COMO USAR**

### **Método 1: Teste Completo Automatizado (RECOMENDADO)**

```bash
# 1. Configure credenciais AWS Academy
./scripts/aws-config.sh

# 2. Execute teste completo com timeout de 2 horas
./scripts/test-eks-safe.sh

# OU com timeout personalizado (em minutos)
./scripts/test-eks-safe.sh 90  # 1.5 horas
```

**O que acontece:**
1. ✅ Verifica pré-requisitos
2. 🏗️ Cria infraestrutura EKS (`terraform apply`)
3. ⚙️ Configura kubectl
4. 🚀 Faz deploy da aplicação
5. 🧪 Executa testes de funcionalidade
6. ⏰ Monitora tempo restante
7. 🧹 **DESTRÓI automaticamente** (`terraform destroy`)

### **Método 2: Teste Manual (Para Debugging)**

```bash
# 1. Configure credenciais
./scripts/aws-config.sh

# 2. Copie arquivo de variáveis
cd environments/dev
cp terraform.tfvars.example terraform.tfvars

# 3. Crie infraestrutura
terraform init
terraform apply

# 4. Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name fiap-soat-cluster

# 5. Deploy aplicação
kubectl apply -f ../../manifests/application/

# 6. Teste aplicação
../../scripts/test-app.sh

# 7. IMPORTANTE: Destrua depois do teste
terraform destroy
```

---

## 💰 **CONTROLE DE CUSTOS**

### **📊 Estimativas:**
- **Teste de 2h**: ~$0.20 USD
- **Teste de 1h**: ~$0.11 USD
- **Teste de 30min**: ~$0.055 USD

### **🚨 Proteções Implementadas:**
- ✅ Timeout automático obrigatório
- ✅ Destroy automático em caso de erro
- ✅ Monitoramento de tempo em tempo real
- ✅ Logs com estimativa de custos
- ✅ Configuração otimizada (1 node t3.micro)

### **⚠️ ALERTAS:**
- **30min restantes**: Aviso para preparar finalização
- **10min restantes**: Salvamento de dados importantes
- **5min restantes**: Finalização de testes

---

## 🧪 **TESTES DISPONÍVEIS**

### **🔍 Script de Teste da Aplicação** (`scripts/test-app.sh`)
```bash
# Testa aplicação já deployada
./scripts/test-app.sh
```

**Verifica:**
- ✅ Status dos pods
- ✅ Configuração dos services  
- ✅ Health checks (`/health`)
- ✅ Endpoints da API (`/products`, `/orders`)
- ✅ Acesso via NodePort
- ✅ Logs e recursos utilizados

### **🌐 Endpoints da Aplicação:**
- **`/`**: Home page com informações básicas
- **`/health`**: Health check (status, timestamp)
- **`/products`**: Lista de produtos (Big Mac, Coca-Cola, etc.)
- **`/orders`**: Lista de pedidos (com status)

---

## 🔧 **CONFIGURAÇÕES OTIMIZADAS**

### **📋 Terraform Variables** (`terraform.tfvars.example`)
```hcl
# Configurações econômicas já aplicadas:
cluster_version = "1.28"                    # Versão estável
enable_nat_gateway = false                  # Economia de $45/mês
use_public_subnets_for_nodes = true        # Nodes com internet sem NAT
node_groups.general.max_size = 1           # Limite de escalonamento
node_groups.general.instance_types = ["t3.micro"]  # Menor instância
```

### **☸️ Kubernetes Resources**
```yaml
# Configurações aplicadas:
resources:
  limits:
    memory: "256Mi"    # Adequado para t3.micro
    cpu: "200m"
  requests:
    memory: "128Mi"
    cpu: "100m"

replicas: 1           # Mínimo necessário
type: NodePort        # Sem Load Balancer ($16/mês economia)
```

---

## 🛡️ **SEGURANÇA E BOAS PRÁTICAS**

### **✅ Implementado:**
- 🔐 Security Groups restritivos
- 🔒 Service Account com RBAC
- 🔑 Secrets para credenciais sensíveis
- 🌐 Network Policies para isolamento
- 📋 Resource limits e requests
- 🏥 Health checks e readiness probes

### **🔒 Secrets Configurados:**
- `DB_USER`: usuário do banco de dados
- `DB_PASSWORD`: senha do banco de dados  
- `JWT_SECRET`: chave para tokens JWT

**Nota**: Valores padrão são de exemplo. **ALTERE em produção!**

---

## 📋 **TROUBLESHOOTING**

### **❌ Erro: "Pods não ficam prontos"**
```bash
# Verificar logs dos pods
kubectl logs -n fiap-soat -l app=fiap-soat-app

# Verificar events
kubectl get events -n fiap-soat --sort-by=.metadata.creationTimestamp
```

### **❌ Erro: "Não consegue acessar externamente"**
- Security Groups podem estar bloqueando porta 30080
- Use port-forward para teste local:
```bash
kubectl port-forward -n fiap-soat svc/fiap-soat-app 8080:80
curl http://localhost:8080/health
```

### **❌ Erro: "Terraform apply falhou"**
```bash
# Verificar credenciais
aws sts get-caller-identity

# Reconfigurar se necessário
./scripts/aws-config.sh
```

### **❌ Erro: "Cluster não responde"**
```bash
# Reconfigurar kubectl
aws eks update-kubeconfig --region us-east-1 --name fiap-soat-cluster

# Verificar nodes
kubectl get nodes
```

---

## 📊 **MONITORAMENTO**

### **📈 Durante o Teste:**
```bash
# Watch recursos em tempo real
watch kubectl get pods,svc -n fiap-soat

# Monitorar logs
kubectl logs -n fiap-soat -l app=fiap-soat-app -f

# Verificar métricas
kubectl top nodes
kubectl top pods -n fiap-soat
```

### **📋 Logs Salvos:**
- Arquivo: `/tmp/eks-test-YYYYMMDD-HHMMSS.log`
- Contém: Timeline completa, erros, custos estimados

---

## 🎯 **PRÓXIMOS PASSOS SUGERIDOS**

1. **🔄 Integração CI/CD**: GitHub Actions para testes automatizados
2. **🐳 Container Registry**: ECR para imagens da aplicação
3. **📊 Monitoring**: Prometheus + Grafana (opcional)
4. **🗄️ Database**: RDS PostgreSQL para persistência
5. **🔒 HTTPS**: Certificate Manager + ALB Ingress
6. **📈 Scaling**: HPA baseado em métricas customizadas

---

## ⚡ **COMANDOS RÁPIDOS**

```bash
# Teste completo em 1 linha
./scripts/aws-config.sh && ./scripts/test-eks-safe.sh 60

# Verificação rápida de custos
echo "Custo estimado por hora: \$0.11"

# Limpeza de emergência
cd environments/dev && terraform destroy -auto-approve

# Status do cluster
kubectl get all -n fiap-soat

# Acesso rápido à aplicação (local)
kubectl port-forward -n fiap-soat svc/fiap-soat-app 8080:80 &
curl http://localhost:8080/health
```

---

**🎉 Agora você tem uma infraestrutura EKS completa, segura e otimizada para AWS Academy!**

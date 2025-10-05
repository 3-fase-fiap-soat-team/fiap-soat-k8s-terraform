# 🎓 AWS Academy Setup Guide

Guia completo para configurar e usar este projeto no ambiente AWS Academy Learner Lab.

## 📋 Índice

- [Limitações do AWS Academy](#limitações-do-aws-academy)
- [Auto-Discovery de Recursos](#auto-discovery-de-recursos)
- [Configuração Inicial](#configuração-inicial)
- [Credenciais e Sessões](#credenciais-e-sessões)
- [VPC e Networking](#vpc-e-networking)
- [Security Groups](#security-groups)
- [IAM Roles](#iam-roles)
- [Troubleshooting](#troubleshooting)

## ⚠️ Limitações do AWS Academy

O AWS Academy Learner Lab possui restrições específicas que este projeto contorna:

### 1. Permissões EC2 Limitadas

**Problema:**
- Role `voclabs` **NÃO tem** permissão `ec2:DescribeVpcs`
- Não pode listar VPCs diretamente
- Data source `aws_vpc` padrão do Terraform falha

**Solução Implementada:**
```hcl
# ❌ Não funciona no AWS Academy
data "aws_vpc" "default" {
  default = true
}

# ✅ Funciona - usa RDS como fonte
data "aws_db_instance" "existing" {
  db_instance_identifier = "fiap-soat-db"
}

data "aws_db_subnet_group" "existing" {
  name = data.aws_db_instance.existing.db_subnet_group
}

locals {
  vpc_id = data.aws_db_subnet_group.existing.vpc_id
  subnets = data.aws_db_subnet_group.existing.subnet_ids
}
```

### 2. Credenciais Temporárias

**Limitação:**
- Sessão expira em **~3 horas**
- Sem renovação automática
- Precisa reconfigurar manualmente

**Solução:**
```bash
# Script de renovação rápida
./scripts/aws-config.sh
```

### 3. Orçamento de $50

**Limitação:**
- Budget fixo de $50 por sessão
- Sem alertas automáticos
- Recursos não limpos custam continuamente

**Recomendações:**
- Sempre destruir recursos após uso
- Usar instâncias t3.micro (menor custo)
- Monitorar custos regularmente

### 4. IAM Roles Pré-criados

**Limitação:**
- Não pode criar IAM roles
- Nomes de roles mudam entre sessões
- Roles têm prefixo aleatório

**Solução: Auto-Discovery**
```hcl
data "aws_iam_roles" "all" {
  name_regex = ".*Lab.*"
}

locals {
  cluster_role_name = [
    for role in data.aws_iam_roles.all.names : role 
    if strcontains(role, "LabEksClusterRole")
  ][0]
}
```

## 🔍 Auto-Discovery de Recursos

### VPC Discovery via RDS

**Por que RDS?**
- Role `voclabs` **TEM** permissão `rds:DescribeDBInstances`
- RDS subnet group contém VPC ID e subnets
- Método confiável e estável

**Implementação:**

```hcl
# 1. Buscar RDS existente
data "aws_db_instance" "existing" {
  db_instance_identifier = "fiap-soat-db"
}

# 2. Obter subnet group do RDS
data "aws_db_subnet_group" "existing" {
  name = data.aws_db_instance.existing.db_subnet_group
}

# 3. Extrair VPC ID e subnets
locals {
  vpc_id = data.aws_db_subnet_group.existing.vpc_id
  subnets = data.aws_db_subnet_group.existing.subnet_ids
}
```

**Teste manual:**
```bash
# Verificar RDS
aws rds describe-db-instances \
  --query 'DBInstances[0].[DBInstanceIdentifier,DBSubnetGroup.VpcId]' \
  --output table

# Ver subnets
aws rds describe-db-instances \
  --query 'DBInstances[0].DBSubnetGroup.Subnets[*].SubnetIdentifier' \
  --output table
```

### IAM Roles Discovery

**Como funciona:**

1. Lista todas as roles com filtro `Lab*`
2. Busca por substring específica
3. Usa primeira match encontrada

**Código:**

```hcl
# Listar roles do Lab
data "aws_iam_roles" "all" {
  name_regex = ".*Lab.*"
}

# Encontrar role do cluster
locals {
  cluster_role_name = try(
    [for role in data.aws_iam_roles.all.names : role 
     if strcontains(role, "LabEksClusterRole")][0],
    ""
  )
  
  node_role_name = try(
    [for role in data.aws_iam_roles.all.names : role 
     if strcontains(role, "LabEksNodeRole")][0],
    ""
  )
}
```

**Teste manual:**
```bash
# Listar roles do Lab
aws iam list-roles --query 'Roles[?contains(RoleName, `Lab`)].RoleName'
```

## 🚀 Configuração Inicial

### 1. Pré-requisitos

```bash
# Verificar ferramentas instaladas
terraform --version  # >= 1.0
aws --version        # >= 2.0
kubectl version --client  # >= 1.27
```

### 2. Renovar Credenciais

```bash
# No AWS Academy Lab:
# 1. Clique em "AWS Details"
# 2. Copie as 3 linhas de credenciais

# Execute o script:
./scripts/aws-config.sh
# Cole as credenciais e pressione Ctrl+D
```

### 3. Verificar Conectividade

```bash
# Teste AWS STS
aws sts get-caller-identity

# Teste RDS (fonte de VPC)
aws rds describe-db-instances --query 'DBInstances[0].DBInstanceIdentifier'

# Teste IAM Roles
aws iam list-roles --query 'Roles[?contains(RoleName, `Lab`)].RoleName'
```

### 4. Configurar Terraform

```bash
cd environments/dev

# Copiar exemplo (se ainda não existe)
cp terraform.tfvars.example terraform.tfvars

# Editar se necessário (opcional)
nano terraform.tfvars
```

### 5. Deploy

```bash
terraform init
terraform plan
terraform apply
```

## 🔐 Credenciais e Sessões

### Anatomia das Credenciais AWS Academy

```ini
[default]
aws_access_key_id = ASIA...      # Temporary Access Key
aws_secret_access_key = ...       # Temporary Secret Key
aws_session_token = IQoJb3...     # Session Token (LONGO!)
```

**Características:**
- Access Key começa com `ASIA` (temporário)
- Session Token é **obrigatório**
- Expira em ~3 horas

### Renovação Automática

O script `aws-config.sh` faz:

1. ✅ Extrai as 3 credenciais
2. ✅ Configura AWS CLI
3. ✅ Define região `us-east-1`
4. ✅ Testa conectividade

### Monitorar Expiração

```bash
# Verificar identidade atual
aws sts get-caller-identity

# Se falhar com AuthFailure = expirou
# Renove com:
./scripts/aws-config.sh
```

### Dicas

- 🔄 Renove credenciais **antes** de operações longas (terraform apply)
- ⏰ Configure alarme para ~2h50min de sessão
- 💾 Salve as credenciais em local seguro durante a sessão

## 🌐 VPC e Networking

### Estrutura da VPC

```
VPC (vpc-0b339aae01a928665)
├── 6 Subnets (descobertas via RDS)
│   ├── subnet-0163ba8f305b2305f
│   ├── subnet-02e9e40dab18eca65
│   ├── subnet-075300612507be681
│   ├── subnet-092b6c45f58308a81
│   ├── subnet-0c19d9c6381598cb5
│   └── subnet-0fa876d173c2dbf62
├── Security Groups
│   ├── Cluster SG (criado pelo Terraform)
│   └── Nodes SG (criado pelo Terraform)
└── RDS Subnet Group (rds-subnet-group)
```

### Configuração EKS Networking

**Subnets:**
- EKS usa **mesmas subnets** do RDS
- Simplifica configuração
- Garante conectividade RDS ↔ EKS

**Endpoints:**
```hcl
endpoint_config = {
  private_access      = true   # API acessível de dentro da VPC
  public_access       = true   # API acessível da internet
  public_access_cidrs = ["0.0.0.0/0"]  # Qualquer IP (dev only!)
}
```

## 🛡️ Security Groups

### Estratégia: Criar Novos SGs

**Recomendado:** `create_security_groups = true`

**Por quê?**
- SGs do RDS têm regras incompatíveis com EKS
- EKS precisa portas específicas (443, 10250, 53, 123)
- Isolamento de segurança

### SG do Cluster EKS

**Egress Rules:**
```hcl
# HTTPS para API server
443/tcp → 0.0.0.0/0

# Kubelet
10250/tcp → 0.0.0.0/0

# DNS
53/tcp,udp → 0.0.0.0/0

# NTP
123/udp → 0.0.0.0/0
```

### SG dos Nodes

**Ingress Rules:**
```hcl
# Tráfego interno entre nodes
0-65535/tcp from self

# DNS interno
53/tcp,udp from self

# HTTPS do cluster
443/tcp from cluster_sg

# Kubelet do cluster
10250/tcp from cluster_sg
```

**Egress Rules:**
```hcl
# Todo tráfego de saída
0-65535 → 0.0.0.0/0
```

### Configuração

```hcl
# terraform.tfvars
create_security_groups = true  # RECOMENDADO

# Ou reutilizar existentes (avançado)
# create_security_groups = false
# cluster_security_group_id = "sg-xxxxx"
# node_security_group_id = "sg-yyyyy"
```

## 👤 IAM Roles

### Roles Pré-criados AWS Academy

AWS Academy cria automaticamente:

- `c173096a4485959l11165982t1w280273-LabEksClusterRole-dZ3qrpPBGk5l`
- `c173096a4485959l11165982t1w280273007-LabEksNodeRole-Z5Cnwlbp9pXj`

**Características:**
- Prefixo aleatório muda entre sessões
- Substring consistente: `LabEksClusterRole` e `LabEksNodeRole`
- Políticas gerenciadas já anexadas

### Auto-Discovery

```hcl
# 1. Listar todas as roles com "Lab"
data "aws_iam_roles" "all" {
  name_regex = ".*Lab.*"
}

# 2. Filtrar por substring
locals {
  cluster_role_name = [
    for role in data.aws_iam_roles.all.names : role 
    if strcontains(role, "LabEksClusterRole")
  ][0]
  
  node_role_name = [
    for role in data.aws_iam_roles.all.names : role 
    if strcontains(role, "LabEksNodeRole")
  ][0]
}

# 3. Obter detalhes
data "aws_iam_role" "cluster_role" {
  name = local.cluster_role_name
}
```

### Políticas Anexadas

**LabEksClusterRole:**
- AmazonEKSClusterPolicy
- AmazonEKSVPCResourceController

**LabEksNodeRole:**
- AmazonEKSWorkerNodePolicy
- AmazonEKS_CNI_Policy
- AmazonEC2ContainerRegistryReadOnly

## 🐛 Troubleshooting

### Erro: VPC not found

**Sintoma:**
```
Error: reading EC2 VPC: StatusCode: 401, AuthFailure
```

**Causa:** Role `voclabs` não tem `ec2:DescribeVpcs`

**Solução:**
1. Verificar RDS ativo:
   ```bash
   aws rds describe-db-instances
   ```
2. Projeto usa auto-discovery via RDS ✅

### Erro: IAM Role not found

**Sintoma:**
```
Error: couldn't find resource (role LabEksClusterRole)
```

**Causa:** Nome hardcoded não existe

**Solução:**
1. Projeto usa auto-discovery ✅
2. Verificar roles disponíveis:
   ```bash
   aws iam list-roles --query 'Roles[?contains(RoleName, `Lab`)].RoleName'
   ```

### Erro: AuthFailure

**Sintoma:**
```
AuthFailure: AWS was not able to validate the provided access credentials
```

**Causa:** Credenciais expiraram

**Solução:**
```bash
./scripts/aws-config.sh
# Cole novas credenciais
```

### Terraform plan demora muito

**Normal:** Terraform valida todos os data sources

**Tempo esperado:**
- `terraform init`: ~10s
- `terraform plan`: ~30s
- `terraform apply`: 20-30min (EKS cluster)

**Dica:** Seja paciente, EKS cluster demora ~20min para criar

### Cluster não fica pronto

**Sintoma:** Cluster travado em "Creating"

**Causas comuns:**
1. Subnets sem rota para internet
2. IAM roles sem políticas corretas
3. Security groups bloqueando comunicação

**Debug:**
```bash
# Ver status no console AWS
aws eks describe-cluster --name fiap-soat-eks-dev

# Ver eventos CloudWatch
aws logs tail /aws/eks/fiap-soat-eks-dev/cluster --follow
```

## 📚 Referências

- [AWS Academy Learner Lab Guide](https://awsacademy.instructure.com/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Documentação do Projeto](../README.md)

## 🎯 Checklist de Deploy

Antes de fazer deploy, verifique:

- [ ] Credenciais AWS renovadas (< 2h50min de sessão)
- [ ] RDS ativo e acessível
- [ ] IAM roles `Lab*` existem
- [ ] terraform.tfvars configurado
- [ ] Orçamento AWS Academy disponível (~$10-15 para EKS)
- [ ] Tempo disponível (~30min para deploy completo)

---

**✨ Pronto para o Deploy!**

Se tudo acima estiver OK, execute:
```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

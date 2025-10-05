# 🔐 Guia de Security Groups - EKS Terraform

## 📋 Visão Geral

O módulo EKS agora suporta **duas estratégias** para Security Groups:

1. ✅ **Criar novos** Security Groups (padrão - isolamento completo)
2. ♻️ **Reutilizar existentes** (compartilhamento de recursos)

---

## 🎯 Estratégia 1: Criar Novos Security Groups (Padrão)

### Quando usar?
- Deploy inicial do EKS
- Quer isolamento total entre recursos
- Não tem SGs pré-existentes

### Configuração
Não precisa fazer nada! É o comportamento padrão:

```hcl
# terraform.tfvars (ou use os defaults)
create_security_groups = true  # Padrão, pode omitir
```

### O que é criado?
1. **Cluster Security Group**:
   - Egress: 443, 10250, 53 (TCP/UDP), 123 (UDP)
   - Ingress: 443 dos nodes

2. **Node Security Group**:
   - Ingress: Todo tráfego de si mesmo
   - Ingress: 443 e 10250 do cluster
   - Egress: Total (0.0.0.0/0)

---

## ♻️ Estratégia 2: Reutilizar Security Groups Existentes

### Quando usar?
- Já tem SGs criados (ex: pelo RDS)
- Quer compartilhar SGs entre recursos
- Reduzir número de security groups na conta

### Pré-requisitos

Os Security Groups existentes **DEVEM**:
- Estar na **mesma VPC** que o EKS
- Ter as **regras necessárias** configuradas (veja abaixo)

### Configuração

```hcl
# terraform.tfvars
create_security_groups     = false
cluster_security_group_id  = "sg-0c96a913a76ab1367"  # Seu SG do cluster
node_security_group_id     = "sg-0123456789abcdef0"  # Seu SG dos nodes
```

### Regras Necessárias nos SGs Existentes

#### Cluster Security Group
```hcl
# Egress
- 443/tcp   -> 0.0.0.0/0  (API Kubernetes)
- 10250/tcp -> 0.0.0.0/0  (Kubelet)
- 53/tcp    -> 0.0.0.0/0  (DNS)
- 53/udp    -> 0.0.0.0/0  (DNS)
- 123/udp   -> 0.0.0.0/0  (NTP)

# Ingress
- 443/tcp <- [node_security_group_id]  (Nodes comunicam com API)
```

#### Node Security Group
```hcl
# Ingress
- 0-65535/tcp <- [self]  (Comunicação entre nodes)
- 53/tcp      <- [self]  (DNS interno)
- 53/udp      <- [self]  (DNS interno)
- 443/tcp     <- [cluster_security_group_id]  (Cluster comunica com nodes)
- 10250/tcp   <- [cluster_security_group_id]  (Kubelet)

# Egress
- 0/all -> 0.0.0.0/0  (Acesso total para internet, registry, etc)
```

---

## 🔍 Como Encontrar SGs Existentes?

### Via AWS CLI
```bash
# Listar todos os SGs da VPC
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=vpc-XXXXXXXX" \
  --query 'SecurityGroups[*].[GroupId,GroupName,Description]' \
  --output table

# Buscar SGs do RDS (exemplo)
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=rds-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text
```

### Via Terraform (Auto-Discovery)
```hcl
# Buscar SG pelo nome
data "aws_security_group" "rds" {
  filter {
    name   = "group-name"
    values = ["rds-sg"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Usar no módulo
cluster_security_group_id = data.aws_security_group.rds.id
```

---

## 📊 Comparação

| Característica | Criar Novos | Reutilizar |
|---------------|-------------|------------|
| Isolamento | ✅ Completo | ⚠️ Compartilhado |
| Simplicidade | ✅ Automático | ⚠️ Manual |
| Segurança | ✅ Alta | ⚠️ Depende |
| Manutenção | ✅ Fácil | ⚠️ Complexa |
| Custo | 💰 Zero (SGs gratuitos) | 💰 Zero |
| Recomendado | ✅ Prod/Dev | ⚠️ Casos específicos |

---

## 🚨 Avisos Importantes

### ⚠️ Compartilhar SGs entre RDS e EKS

**NÃO RECOMENDADO** por questões de segurança:
- RDS precisa apenas porta 5432
- EKS precisa muitas portas (443, 10250, DNS, etc)
- Compartilhar = aumentar superfície de ataque

### ✅ Alternativa Segura

Crie SGs separados mas na mesma VPC:
```hcl
# RDS
rds_security_group_id = "sg-rds-12345"  # Apenas 5432

# EKS Cluster
cluster_security_group_id = "sg-eks-cluster-67890"  # 443, 10250, DNS

# EKS Nodes
node_security_group_id = "sg-eks-nodes-abcdef"  # Tudo
```

E permita comunicação específica:
```hcl
# Nodes podem acessar RDS
resource "aws_security_group_rule" "nodes_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = var.node_security_group_id
  security_group_id        = var.rds_security_group_id
}
```

---

## 📝 Exemplos Práticos

### Exemplo 1: Deploy Padrão (Criar Novos)
```bash
cd environments/dev
terraform apply
# SGs serão criados automaticamente
```

### Exemplo 2: Reutilizar SGs Existentes
```bash
cd environments/dev
cp terraform.tfvars.use-existing-sgs terraform.tfvars

# Editar terraform.tfvars:
# - Descomentar create_security_groups = false
# - Adicionar IDs dos SGs existentes

terraform apply
```

### Exemplo 3: Auto-Discovery de SGs
```hcl
# main.tf
data "aws_security_group" "existing_cluster" {
  count = var.create_security_groups ? 0 : 1
  
  filter {
    name   = "tag:Name"
    values = ["my-existing-cluster-sg"]
  }
}

module "eks" {
  source = "../../modules/eks"
  
  create_security_groups    = false
  cluster_security_group_id = data.aws_security_group.existing_cluster[0].id
  # ...
}
```

---

## 🔧 Troubleshooting

### Erro: "InvalidGroup.NotFound"
- **Causa**: SG ID inválido ou não existe
- **Solução**: Verifique o ID com `aws ec2 describe-security-groups`

### Erro: "InvalidParameterValue: The security group does not belong to VPC"
- **Causa**: SG está em VPC diferente do cluster
- **Solução**: Use SGs da mesma VPC ou crie novos

### Pods não conseguem comunicar
- **Causa**: Faltam regras no SG dos nodes
- **Solução**: Adicione regra self-referencing (source = self)

### RDS não aceita conexões do EKS
- **Causa**: Falta regra no SG do RDS permitindo tráfego dos nodes
- **Solução**: 
  ```bash
  aws ec2 authorize-security-group-ingress \
    --group-id sg-rds-12345 \
    --protocol tcp --port 5432 \
    --source-group sg-eks-nodes-67890
  ```

---

## 📚 Referências

- [AWS EKS Security Group Requirements](https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html)
- [EKS Best Practices - Network Security](https://aws.github.io/aws-eks-best-practices/security/docs/network/)
- [Terraform AWS Provider - Security Groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)

---

## ✅ Checklist de Validação

Antes de usar SGs existentes, valide:

- [ ] SGs estão na mesma VPC que o EKS?
- [ ] Cluster SG tem egress 443, 10250, 53, 123?
- [ ] Node SG tem ingress self-referencing?
- [ ] Node SG tem ingress 443 e 10250 do cluster?
- [ ] Node SG tem egress total (0.0.0.0/0)?
- [ ] Testou conectividade entre pods?
- [ ] Testou conectividade com RDS (se aplicável)?

---

**Recomendação Final**: Para produção, sempre crie SGs específicos para o EKS. Para desenvolvimento/testes, você pode compartilhar se necessário, mas entenda os riscos de segurança.

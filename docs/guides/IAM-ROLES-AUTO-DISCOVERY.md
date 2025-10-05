# 🔐 IAM Roles Auto-Discovery - Corrigindo GitHub Actions

## 🚨 Erro no GitHub Actions

```
Error: reading IAM Role (c173096a4485959l11165982t1w280273-LabEksClusterRole-jiF0LvC4kZ5O): 
couldn't find resource
```

**Causa**: Nomes de IAM Roles hardcoded que não existem no ambiente do CI/CD.

---

## ✅ Solução: Auto-Discovery

### Antes (❌ Hardcoded)
```hcl
data "aws_iam_role" "cluster_role" {
  name = "c173096a4485959l11165982t1w280273-LabEksClusterRole-jiF0LvC4kZ5O"
}
```

### Depois (✅ Auto-Discovery)
```hcl
# Lista todas as roles com "Lab" no nome
data "aws_iam_roles" "all" {
  name_regex = ".*Lab.*"
}

# Filtra dinamicamente
locals {
  cluster_role_name = try(
    [for role in data.aws_iam_roles.all.names : role if strcontains(role, "LabEksClusterRole")][0],
    var.cluster_role_name != null ? var.cluster_role_name : ""
  )
}

# Usa o nome descoberto
data "aws_iam_role" "cluster_role" {
  name = local.cluster_role_name
}
```

---

## 🔍 Como Funciona

1. **Lista**: Busca todas as roles com "Lab" no nome
2. **Filtra**: Loop encontra roles que contêm "LabEksClusterRole" ou "LabEksNodeRole"
3. **Fallback**: Se não encontrar, usa variável manual (opcional)
4. **Usa**: EKS aplica a role descoberta

---

## 🎯 Benefícios

- ✅ Funciona em **qualquer** conta AWS Academy
- ✅ Funciona no **GitHub Actions** sem configuração
- ✅ Funciona em **múltiplos labs/sessões**
- ✅ **Zero configuração** necessária
- ✅ **Fallback manual** disponível

---

## 🧪 Testando

```bash
# Listar roles disponíveis
aws iam list-roles --query 'Roles[?contains(RoleName, `Lab`)].RoleName'

# Terraform console (debug)
terraform console
> local.cluster_role_name
> local.node_role_name
```

---

## ⚠️ Troubleshooting

### Erro: "couldn't find resource"

**Solução 1** - Verificar se roles existem:
```bash
aws iam list-roles --query 'Roles[?contains(RoleName, `Lab`)].RoleName'
```

**Solução 2** - Especificar manualmente:
```hcl
# terraform.tfvars
cluster_role_name = "nome-correto-da-role"
node_role_name    = "nome-correto-da-node-role"
```

---

**Status**: ✅ Implementado  
**Ambiente**: AWS Academy + GitHub Actions  
**Portabilidade**: Total

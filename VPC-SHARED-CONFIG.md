# 🔗 EKS + RDS - VPC Compartilhada

## 🎯 **Nova Arquitetura**

O EKS agora **reutiliza a VPC do RDS** em vez de criar uma própria, garantindo conectividade direta e economia de recursos.

### 📊 **Configuração VPC Compartilhada:**

```hcl
# VPC do RDS (já existente)
existing_vpc_id = "vpc-0bc479b582e33b241"

# Subnets compartilhadas
rds_subnet_ids = [
  "subnet-0c00fd754c4fe4305",  # Público 1
  "subnet-0c5f846c7a41656d4",  # Público 2  
  "subnet-05296f706c91a1df8",  # Público 3
  "subnet-0c534eacf07fde00c",  # Privado 1
  "subnet-01cf476ef5fe31d92",  # Privado 2
  "subnet-0f7c2a12c4f68b254"   # Privado 3
]
```

### 🔄 **Mudanças Implementadas:**

#### **ANTES: VPC Separada**
```hcl
# Criava VPC nova
module "vpc" {
  source = "../../modules/vpc"
  # ... configurações próprias
}
```

#### **DEPOIS: VPC Compartilhada** 
```hcl
# Usa VPC existente do RDS
data "aws_vpc" "existing" {
  id = var.existing_vpc_id
}

# Subnets do RDS organizadas
locals {
  public_subnet_ids  = slice(local.rds_subnet_ids, 0, 3)
  private_subnet_ids = slice(local.rds_subnet_ids, 3, 6)
}
```

### 🚀 **Deploy com Nova Configuração:**

```bash
# 1. Usar configuração compartilhada
cp terraform.tfvars.rds-shared terraform.tfvars

# 2. Limpar estado anterior (se necessário)
terraform state rm module.vpc  # Remove VPC antiga

# 3. Inicializar com nova configuração
terraform init
terraform plan
terraform apply
```

### ✅ **Benefícios:**

1. **🔗 Conectividade Direta:** EKS → RDS na mesma VPC
2. **💰 Economia:** Sem duplicação de recursos de rede
3. **🛡️ Segurança:** Security groups otimizados
4. **⚡ Performance:** Latência reduzida
5. **🧹 Simplicidade:** Gestão unificada da rede

### 🔧 **Verificações Necessárias:**

```bash
# Validar VPC
aws ec2 describe-vpcs --vpc-ids vpc-0bc479b582e33b241

# Validar subnets
aws ec2 describe-subnets --subnet-ids subnet-0c00fd754c4fe4305

# Testar conectividade EKS → RDS
kubectl run test-pod --image=postgres:13 --rm -it -- psql -h <rds-endpoint>
```

### 📋 **Próximos Passos:**

1. ✅ **EKS adaptado** para VPC do RDS
2. ⏳ **Deploy + teste** da nova configuração
3. ⏳ **Conectar aplicação** NestJS ao RDS
4. ⏳ **Integrar Lambda** de autenticação
5. ⏳ **Teste end-to-end** completo

---

**🎯 O EKS agora está pronto para compartilhar recursos com RDS de forma eficiente!**
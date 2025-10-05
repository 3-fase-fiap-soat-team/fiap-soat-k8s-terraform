# 🛠️ Scripts Auxiliares

Scripts úteis para gerenciamento da infraestrutura EKS e AWS Academy.

## 📋 Scripts Disponíveis

### 1. `aws-config.sh` - Renovar Credenciais AWS Academy

**Uso:**
```bash
./scripts/aws-config.sh
```

**Descrição:**  
Configura rapidamente as credenciais AWS Academy que expiram a cada ~3 horas.

**Como usar:**
1. Acesse o AWS Academy Lab
2. Clique em "AWS Details"
3. Copie as 3 linhas de credenciais:
   ```
   aws_access_key_id=...
   aws_secret_access_key=...
   aws_session_token=...
   ```
4. Execute o script e cole as credenciais
5. Pressione `Ctrl+D` para finalizar

**Output:**
- ✅ Configura AWS CLI automaticamente
- ✅ Testa conexão com `aws sts get-caller-identity`
- ✅ Define região padrão como `us-east-1`

---

### 2. `deploy.sh` - Deploy Completo Automatizado

**Uso:**
```bash
./scripts/deploy.sh
```

**Descrição:**  
Script completo de deploy da infraestrutura EKS com checagem de pré-requisitos, renovação de credenciais, e limpeza de recursos órfãos.

**Funcionalidades:**
- 🔍 Verifica pré-requisitos (terraform, aws-cli, kubectl)
- 🔄 Renova credenciais AWS se necessário
- 🧹 Limpa recursos órfãos antes do deploy
- 🚀 Executa `terraform init`, `plan` e `apply`
- ⚙️ Configura `kubectl` automaticamente
- ✅ Valida o cluster após deploy

**Configurável:**
- Define diretório Terraform: `TERRAFORM_DIR`
- Timeout para operações
- Modo verbose com logs detalhados

---

### 3. `deploy-from-ecr.sh` - Deploy de Aplicação do ECR

**Uso:**
```bash
./scripts/deploy-from-ecr.sh
```

**Descrição:**  
Faz deploy de uma aplicação containerizada do Amazon ECR para o cluster EKS.

**Pré-requisitos:**
- Cluster EKS funcionando
- Imagem no ECR
- `kubectl` configurado

**Funcionalidades:**
- 📦 Puxa imagem do ECR
- 🚀 Aplica manifests Kubernetes (`namespace`, `deployment`, `service`)
- ✅ Verifica status do deployment
- 🔍 Lista pods e services criados

---

### 4. `force-destroy.sh` - Destruir Recursos com Força

**Uso:**
```bash
./scripts/force-destroy.sh
```

**⚠️ ATENÇÃO:** Este script **destrói TODOS os recursos** provisionados!

**Descrição:**  
Remove forçadamente toda a infraestrutura Terraform, incluindo recursos que possam estar protegidos.

**O que faz:**
- 🗑️ Executa `terraform destroy -auto-approve`
- 🧹 Remove arquivos `.terraform/`
- 🔄 Força remoção de recursos travados
- ⚠️ **SEM confirmação** - use com cuidado!

**Quando usar:**
- Limpeza de ambiente de testes
- Recursos travados que não destroem normalmente
- Reset completo da infraestrutura

---

### 5. `test-eks-academy.sh` - Testar Configuração EKS

**Uso:**
```bash
./scripts/test-eks-academy.sh
```

**Descrição:**  
Script de validação e testes da configuração EKS específica para AWS Academy.

**Testes realizados:**
- ✅ Credenciais AWS válidas
- ✅ Cluster EKS acessível
- ✅ Nodes ativos e prontos
- ✅ Add-ons instalados (vpc-cni, kube-proxy, coredns)
- ✅ Conectividade de rede
- ✅ IRSA (IAM Roles for Service Accounts) funcionando

**Output:**
- Relatório completo de status
- Diagnóstico de problemas
- Sugestões de correção

---

## 🔧 Configuração Comum

### Variáveis de Ambiente

Todos os scripts respeitam estas variáveis:

```bash
export AWS_REGION=us-east-1
export AWS_PROFILE=default
export TERRAFORM_DIR=environments/dev
```

### Logs

Os scripts geram logs detalhados em caso de erro. Use modo verbose:

```bash
DEBUG=1 ./scripts/deploy.sh
```

## 📚 Exemplos de Uso

### Workflow Completo de Deploy

```bash
# 1. Renovar credenciais
./scripts/aws-config.sh

# 2. Deploy da infraestrutura
./scripts/deploy.sh

# 3. Testar configuração
./scripts/test-eks-academy.sh

# 4. Deploy da aplicação
./scripts/deploy-from-ecr.sh
```

### Limpeza e Reset

```bash
# Destruir tudo e recomeçar
./scripts/force-destroy.sh

# Renovar credenciais
./scripts/aws-config.sh

# Deploy novamente
./scripts/deploy.sh
```

## ⚠️ Notas Importantes

1. **Credenciais AWS Academy:**  
   Expiram a cada ~3 horas. Sempre renove antes de rodar scripts longos.

2. **Timeouts:**  
   EKS cluster pode levar 20-30 minutos para provisionar. Seja paciente.

3. **Custos:**  
   AWS Academy tem limite de $50. Monitor o uso com `aws ce get-cost-and-usage`.

4. **Cleanup:**  
   Sempre destrua recursos após testes para não desperdiçar orçamento.

## 🐛 Troubleshooting

### Script trava em "Waiting for cluster..."

**Causa:** EKS está demorando para provisionar  
**Solução:** Aguarde até 30 minutos ou verifique logs no console AWS

### "AuthFailure: AWS was not able to validate credentials"

**Causa:** Credenciais expiraram  
**Solução:** Execute `./scripts/aws-config.sh` novamente

### "Error: VPC not found"

**Causa:** AWS Academy `voclabs` role não tem permissão `ec2:DescribeVpcs`  
**Solução:** O Terraform usa auto-discovery via RDS - verifique se RDS está ativo

### "kubectl: command not found"

**Causa:** kubectl não instalado  
**Solução:** 
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

## 📞 Suporte

Para problemas com scripts:

1. Verifique logs em `/tmp/` (scripts geram logs temporários)
2. Execute com `DEBUG=1` para verbose output
3. Consulte [troubleshooting docs](../docs/troubleshooting/)
4. Abra uma [issue no GitHub](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/issues)

---

**✨ Happy Scripting!**

# 🛠️ Scripts Auxiliares# 🛠️ Scripts Auxiliares



Scripts úteis para gerenciamento da infraestrutura EKS e AWS Academy.Scripts úteis para gerenciamento da infraestrutura EKS e AWS Academy.



> 📖 **English version:** [README.en.md](README.en.md)## 📋 Scripts Disponíveis



## 📋 Scripts Disponíveis### 1. `aws-config.sh` - Renovar Credenciais AWS Academy



### 1. `aws-config.sh` - Renovar Credenciais AWS Academy**Uso:**

```bash

**Uso:**./scripts/aws-config.sh

```bash```

./scripts/aws-config.sh

```**Descrição:**  

Configura rapidamente as credenciais AWS Academy que expiram a cada ~3 horas.

**Descrição:**  

Configura rapidamente as credenciais AWS Academy que expiram a cada ~3 horas.**Como usar:**

1. Acesse o AWS Academy Lab

**Como usar:**2. Clique em "AWS Details"

1. Acesse o AWS Academy Lab3. Copie as 3 linhas de credenciais:

2. Clique em "AWS Details"   ```

3. Copie as 3 linhas de credenciais:   aws_access_key_id=...

   ```   aws_secret_access_key=...

   aws_access_key_id=...   aws_session_token=...

   aws_secret_access_key=...   ```

   aws_session_token=...4. Execute o script e cole as credenciais

   ```5. Pressione `Ctrl+D` para finalizar

4. Execute o script e cole as credenciais

5. Pressione `Ctrl+D` para finalizar**Output:**

- ✅ Configura AWS CLI automaticamente

**Output:**- ✅ Testa conexão com `aws sts get-caller-identity`

- ✅ Configura AWS CLI automaticamente- ✅ Define região padrão como `us-east-1`

- ✅ Testa conexão com `aws sts get-caller-identity`

- ✅ Define região padrão como `us-east-1`---



---### 2. `deploy.sh` - Deploy Completo Automatizado



### 2. `deploy.sh` - Deploy Completo Automatizado**Uso:**

```bash

**Uso:**./scripts/deploy.sh

```bash```

./scripts/deploy.sh

```**Descrição:**  

Script completo de deploy da infraestrutura EKS com checagem de pré-requisitos, renovação de credenciais, e limpeza de recursos órfãos.

**Descrição:**  

Script completo de deploy da infraestrutura EKS com checagem de pré-requisitos, renovação de credenciais, e limpeza de recursos órfãos.**Funcionalidades:**

- 🔍 Verifica pré-requisitos (terraform, aws-cli, kubectl)

**Funcionalidades:**- 🔄 Renova credenciais AWS se necessário

- 🔍 Verifica pré-requisitos (terraform, aws-cli, kubectl)- 🧹 Limpa recursos órfãos antes do deploy

- 🔄 Renova credenciais AWS se necessário- 🚀 Executa `terraform init`, `plan` e `apply`

- 🧹 Limpa recursos órfãos antes do deploy- ⚙️ Configura `kubectl` automaticamente

- 🚀 Executa `terraform init`, `plan` e `apply`- ✅ Valida o cluster após deploy

- ⚙️ Configura `kubectl` automaticamente

- ✅ Valida o cluster após deploy**Configurável:**

- Define diretório Terraform: `TERRAFORM_DIR`

**Configurável:**- Timeout para operações

- Define diretório Terraform: `TERRAFORM_DIR`- Modo verbose com logs detalhados

- Timeout para operações

- Modo verbose com logs detalhados---



---### 3. `deploy-from-ecr.sh` - Deploy de Aplicação do ECR



### 3. `deploy-from-ecr.sh` - Deploy de Aplicação do ECR**Uso:**

```bash

**Uso:**./scripts/deploy-from-ecr.sh

```bash```

./scripts/deploy-from-ecr.sh

```**Descrição:**  

Faz deploy de uma aplicação containerizada do Amazon ECR para o cluster EKS.

**Descrição:**  

Faz deploy de uma aplicação containerizada do Amazon ECR para o cluster EKS.**Pré-requisitos:**

- Cluster EKS funcionando

**Pré-requisitos:**- Imagem no ECR

- Cluster EKS funcionando- `kubectl` configurado

- Imagem no ECR

- `kubectl` configurado**Funcionalidades:**

- 📦 Puxa imagem do ECR

**Funcionalidades:**- 🚀 Aplica manifests Kubernetes (`namespace`, `deployment`, `service`)

- 📦 Puxa imagem do ECR- ✅ Verifica status do deployment

- 🚀 Aplica manifests Kubernetes (`namespace`, `deployment`, `service`)- 🔍 Lista pods e services criados

- ✅ Verifica status do deployment

- 🔍 Lista pods e services criados---



---### 4. `force-destroy.sh` - Destruir Recursos com Força



### 4. `force-destroy.sh` - Destruir Recursos com Força**Uso:**

```bash

**Uso:**./scripts/force-destroy.sh

```bash```

./scripts/force-destroy.sh

```**⚠️ ATENÇÃO:** Este script **destrói TODOS os recursos** provisionados!



**⚠️ ATENÇÃO:** Este script **destrói TODOS os recursos** provisionados!**Descrição:**  

Remove forçadamente toda a infraestrutura Terraform, incluindo recursos que possam estar protegidos.

**Descrição:**  

Remove forçadamente toda a infraestrutura Terraform, incluindo recursos que possam estar protegidos.**O que faz:**

- 🗑️ Executa `terraform destroy -auto-approve`

**O que faz:**- 🧹 Remove arquivos `.terraform/`

- 🗑️ Executa `terraform destroy -auto-approve`- 🔄 Força remoção de recursos travados

- 🧹 Remove arquivos `.terraform/`- ⚠️ **SEM confirmação** - use com cuidado!

- 🔄 Força remoção de recursos travados

- ⚠️ **SEM confirmação** - use com cuidado!**Quando usar:**

- Limpeza de ambiente de testes

**Quando usar:**- Recursos travados que não destroem normalmente

- Limpeza de ambiente de testes- Reset completo da infraestrutura

- Recursos travados que não destroem normalmente

- Reset completo da infraestrutura---



---### 5. `test-eks-academy.sh` - Testar Configuração EKS



### 5. `test-eks-academy.sh` - Testar Configuração EKS**Uso:**

```bash

**Uso:**./scripts/test-eks-academy.sh

```bash```

./scripts/test-eks-academy.sh

```**Descrição:**  

Script de validação e testes da configuração EKS específica para AWS Academy.

**Descrição:**  

Script de validação e testes da configuração EKS específica para AWS Academy.**Testes realizados:**

- ✅ Credenciais AWS válidas

**Testes realizados:**- ✅ Cluster EKS acessível

- ✅ Credenciais AWS válidas- ✅ Nodes ativos e prontos

- ✅ Cluster EKS acessível- ✅ Add-ons instalados (vpc-cni, kube-proxy, coredns)

- ✅ Nodes ativos e prontos- ✅ Conectividade de rede

- ✅ Add-ons instalados (vpc-cni, kube-proxy, coredns)- ✅ IRSA (IAM Roles for Service Accounts) funcionando

- ✅ Conectividade de rede

- ✅ IRSA (IAM Roles for Service Accounts) funcionando**Output:**

- Relatório completo de status

**Output:**- Diagnóstico de problemas

- Relatório completo de status- Sugestões de correção

- Diagnóstico de problemas

- Sugestões de correção---



---## 🔧 Configuração Comum



## 🔧 Configuração Comum### Variáveis de Ambiente



### Variáveis de AmbienteTodos os scripts respeitam estas variáveis:



Todos os scripts respeitam estas variáveis:```bash

export AWS_REGION=us-east-1

```bashexport AWS_PROFILE=default

export AWS_REGION=us-east-1export TERRAFORM_DIR=environments/dev

export AWS_PROFILE=default```

export TERRAFORM_DIR=environments/dev

```### Logs



### LogsOs scripts geram logs detalhados em caso de erro. Use modo verbose:



Os scripts geram logs detalhados em caso de erro. Use modo verbose:```bash

DEBUG=1 ./scripts/deploy.sh

```bash```

DEBUG=1 ./scripts/deploy.sh

```## 📚 Exemplos de Uso



## 📚 Exemplos de Uso### Workflow Completo de Deploy



### Workflow Completo de Deploy```bash

# 1. Renovar credenciais

```bash./scripts/aws-config.sh

# 1. Renovar credenciais

./scripts/aws-config.sh# 2. Deploy da infraestrutura

./scripts/deploy.sh

# 2. Deploy da infraestrutura

./scripts/deploy.sh# 3. Testar configuração

./scripts/test-eks-academy.sh

# 3. Testar configuração

./scripts/test-eks-academy.sh# 4. Deploy da aplicação

./scripts/deploy-from-ecr.sh

# 4. Deploy da aplicação```

./scripts/deploy-from-ecr.sh

```### Limpeza e Reset



### Limpeza e Reset```bash

# Destruir tudo e recomeçar

```bash./scripts/force-destroy.sh

# Destruir tudo e recomeçar

./scripts/force-destroy.sh# Renovar credenciais

./scripts/aws-config.sh

# Renovar credenciais

./scripts/aws-config.sh# Deploy novamente

./scripts/deploy.sh

# Deploy novamente```

./scripts/deploy.sh

```## ⚠️ Notas Importantes



## ⚠️ Notas Importantes1. **Credenciais AWS Academy:**  

   Expiram a cada ~3 horas. Sempre renove antes de rodar scripts longos.

1. **Credenciais AWS Academy:**  

   Expiram a cada ~3 horas. Sempre renove antes de rodar scripts longos.2. **Timeouts:**  

   EKS cluster pode levar 20-30 minutos para provisionar. Seja paciente.

2. **Timeouts:**  

   EKS cluster pode levar 20-30 minutos para provisionar. Seja paciente.3. **Custos:**  

   AWS Academy tem limite de $50. Monitor o uso com `aws ce get-cost-and-usage`.

3. **Custos:**  

   AWS Academy tem limite de $50. Monitore o uso com `aws ce get-cost-and-usage`.4. **Cleanup:**  

   Sempre destrua recursos após testes para não desperdiçar orçamento.

4. **Cleanup:**  

   Sempre destrua recursos após testes para não desperdiçar orçamento.## 🐛 Troubleshooting



## 🐛 Troubleshooting### Script trava em "Waiting for cluster..."



### Script trava em "Aguardando cluster..."**Causa:** EKS está demorando para provisionar  

**Solução:** Aguarde até 30 minutos ou verifique logs no console AWS

**Causa:** EKS está demorando para provisionar  

**Solução:** Aguarde até 30 minutos ou verifique logs no console AWS### "AuthFailure: AWS was not able to validate credentials"



### "AuthFailure: AWS não conseguiu validar as credenciais"**Causa:** Credenciais expiraram  

**Solução:** Execute `./scripts/aws-config.sh` novamente

**Causa:** Credenciais expiraram  

**Solução:** Execute `./scripts/aws-config.sh` novamente### "Error: VPC not found"



### "Error: VPC não encontrada"**Causa:** AWS Academy `voclabs` role não tem permissão `ec2:DescribeVpcs`  

**Solução:** O Terraform usa auto-discovery via RDS - verifique se RDS está ativo

**Causa:** RDS não está ativo ou não foi encontrado  

**Solução:** Verifique se o RDS `fiap-soat-db` existe e está disponível:### "kubectl: command not found"

```bash

aws rds describe-db-instances --query 'DBInstances[0].DBInstanceIdentifier'**Causa:** kubectl não instalado  

```**Solução:** 

```bash

### "kubectl: command not found"curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl

**Causa:** kubectl não instalado  sudo mv kubectl /usr/local/bin/

**Solução:** ```

```bash

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"## 📞 Suporte

chmod +x kubectl

sudo mv kubectl /usr/local/bin/Para problemas com scripts:

```

1. Verifique logs em `/tmp/` (scripts geram logs temporários)

## 📞 Suporte2. Execute com `DEBUG=1` para verbose output

3. Consulte [troubleshooting docs](../docs/troubleshooting/)

Para problemas com scripts:4. Abra uma [issue no GitHub](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/issues)



1. Verifique logs em `/tmp/` (scripts geram logs temporários)---

2. Execute com `DEBUG=1` para output detalhado

3. Consulte [documentação de troubleshooting](../docs/troubleshooting/)**✨ Happy Scripting!**

4. Abra uma [issue no GitHub](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/issues)

---

**✨ Bons Scripts!**

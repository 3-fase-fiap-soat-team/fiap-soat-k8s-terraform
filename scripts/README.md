# 🚀 FIAP SOAT - Scripts Finais para Trabalho

## 📋 **Scripts Essenciais Organizados**

### **🔧 1. Configuração Inicial**
```bash
# Configurar credenciais e ambiente AWS
./scripts/aws-config.sh
```

### **🚀 2. Deploy da Solução Completa**
```bash
# Deploy EKS + Aplicação NestJS (solução completa)
./scripts/deploy.sh

# Deploy apenas da aplicação (se EKS já existir)
./scripts/deploy-from-ecr.sh
```

### **🧪 3. Testes**
```bash
# Teste de infraestrutura EKS (evitar custos)
./scripts/test-eks-academy.sh

# Testes de carga da aplicação
./load-tests/run-all-tests.sh
```

### **🧹 4. Limpeza e Destruição**
```bash
# Destruição controlada (padrão)
./scripts/destroy.sh

# Limpeza forçada (emergência)
./scripts/force-destroy.sh
```

---

## 🎯 **Fluxo Recomendado para Trabalho Final**

### **📋 Preparação:**
```bash
# 1. Configurar ambiente
./scripts/aws-config.sh
```

### **🚀 Deploy:**
```bash
# 2. Deploy completo da solução
./scripts/deploy.sh
```

### **🧪 Validação:**
```bash
# 3. Testes de infraestrutura
./scripts/test-eks-academy.sh

# 4. Testes de carga
./load-tests/run-all-tests.sh
```

### **🧹 Finalização:**
```bash
# 5. Limpeza para evitar custos
./scripts/destroy.sh
```

---

## 📊 **Descrição dos Scripts**

### **🔧 aws-config.sh**
- **Função**: Configuração inicial do ambiente AWS
- **Uso**: Configurar credenciais, região, perfil
- **Quando**: Primeira execução ou mudança de ambiente

### **🚀 deploy.sh** 
- **Função**: Deploy completo EKS + Aplicação NestJS
- **Uso**: Subida da solução completa do zero
- **Inclui**: VPC, EKS, Node Groups, LoadBalancer, Aplicação

### **🚀 deploy-from-ecr.sh**
- **Função**: Deploy apenas da aplicação NestJS
- **Uso**: Quando EKS já existe, apenas aplicação
- **Pré-req**: Imagem no ECR, cluster EKS ativo

### **🧪 test-eks-academy.sh**
- **Função**: Testes de infraestrutura EKS
- **Uso**: Validar cluster, nodes, conectividade
- **Objetivo**: Evitar custos testando antes do deploy full

### **🧪 load-tests/run-all-tests.sh**
- **Função**: Testes de carga da aplicação
- **Uso**: Validar performance, escalabilidade
- **Inclui**: Smoke tests, load tests, stress tests

### **🧹 destroy.sh**
- **Função**: Destruição controlada dos recursos
- **Uso**: Limpeza padrão para evitar custos
- **Inclui**: Menu de opções, confirmações

### **🧹 force-destroy.sh**
- **Função**: Limpeza forçada de emergência
- **Uso**: Quando destroy.sh falha
- **Cuidado**: Mais agressivo, usar com cautela

---

## 🗂️ **Scripts Arquivados**

Os scripts redundantes foram movidos para `scripts/archived/` e incluídos no `.gitignore`:

- `build-and-push-*.sh` - Redundantes (incluídos no deploy)
- `test-*.sh` específicos - Redundantes (test-eks-academy.sh é completo)
- `setup-dev.sh` - Redundante (aws-config.sh é suficiente)
- `upload-via-local.sh` - Específico para sessão anterior
- Outros utilitários menores

---

## 🎯 **Benefícios da Limpeza**

### **✅ Simplicidade:**
- **6 scripts** essenciais vs **20+ scripts** anteriores
- **Fluxo claro** e documentado
- **Menos confusão** na escolha do script

### **✅ Manutenibilidade:**
- **Scripts focados** em uma função específica
- **Documentação clara** de cada script
- **Fácil troubleshooting**

### **✅ Trabalho Final:**
- **Scripts alinhados** com requisitos FIAP
- **Fluxo otimizado** para apresentação
- **Limpeza automática** para evitar custos

---

**🎯 Agora temos um conjunto limpo e focado de scripts para o trabalho final!**

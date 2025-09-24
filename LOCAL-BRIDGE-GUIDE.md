# 🔄 Guia: Upload de Imagem Docker via Máquina Local para ECR

## 📋 Cenário
Você tem uma imagem Docker construída no ambiente remoto e quer fazer upload via sua máquina local para o ECR.

## 🎯 Estratégia: Máquina Local como Bridge

### **Método 1: Docker Save/Load (Recomendado)**

#### **1. No Ambiente Remoto (onde você está agora):**
```bash
# Salvar a imagem Docker como arquivo TAR
docker save fiap-soat-nestjs-app:latest > fiap-soat-nestjs-app.tar

# Verificar o tamanho do arquivo
ls -lh fiap-soat-nestjs-app.tar

# Comprimir para reduzir tamanho (opcional)
gzip fiap-soat-nestjs-app.tar
# Resultado: fiap-soat-nestjs-app.tar.gz
```

#### **2. Transferir para sua máquina local:**
```bash
# Opção A: SCP (se você tem SSH)
scp user@remote-server:/path/fiap-soat-nestjs-app.tar.gz ./

# Opção B: Download via link temporário
# (se você pode criar um link de download)

# Opção C: Usar serviços de compartilhamento
# - Google Drive, Dropbox, etc.
# - WeTransfer para arquivos grandes
```

#### **3. Na sua máquina local:**
```bash
# Descompactar (se compactado)
gunzip fiap-soat-nestjs-app.tar.gz

# Carregar a imagem no Docker local
docker load < fiap-soat-nestjs-app.tar

# Verificar se a imagem foi carregada
docker images | grep fiap-soat

# Fazer tag para ECR
docker tag fiap-soat-nestjs-app:latest 280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest

# Login no ECR (na sua máquina com suas credenciais)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 280273007505.dkr.ecr.us-east-1.amazonaws.com

# Push para ECR
docker push 280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest
```

### **Método 2: Registry Intermediário (Docker Hub)**

#### **1. No ambiente remoto:**
```bash
# Fazer tag para Docker Hub público temporário
docker tag fiap-soat-nestjs-app:latest seu-username/fiap-soat-temp:latest

# Login no Docker Hub
docker login

# Push temporário para Docker Hub
docker push seu-username/fiap-soat-temp:latest
```

#### **2. Na sua máquina local:**
```bash
# Pull da imagem do Docker Hub
docker pull seu-username/fiap-soat-temp:latest

# Tag para ECR
docker tag seu-username/fiap-soat-temp:latest 280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest

# Push para ECR
docker push 280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest

# Limpar Docker Hub (opcional)
# Deletar o repositório temporário no Docker Hub
```

### **Método 3: Rebuild Local**

Se você tem o código fonte:
```bash
# Na sua máquina local:
git clone <repository-url>
cd fiap-soat-application

# Build local
docker build -t fiap-soat-nestjs-app:latest .

# Tag e push para ECR
docker tag fiap-soat-nestjs-app:latest 280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest
docker push 280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest
```

## 🚀 Vamos Implementar o Método 1 (Docker Save)?

Vou preparar os comandos para você executar no ambiente remoto:

### **Estimativas de Tamanho:**
- **Imagem original**: 2.24GB
- **Arquivo .tar**: ~2.2GB 
- **Arquivo .tar.gz**: ~800MB-1.2GB (compressão)
- **Tempo download**: Depende da sua conexão (5-15min para 1GB)

### **Vantagens do Método 1:**
- ✅ Preserva exatamente a imagem construída
- ✅ Não precisa de registry intermediário
- ✅ Funciona offline após download
- ✅ Não expõe a imagem publicamente

### **Comandos Prontos para Executar:**

Quer que eu execute os comandos de preparação da imagem para download?

## 📋 Checklist Final

1. ⬜ Salvar imagem como arquivo TAR
2. ⬜ Comprimir arquivo (opcional)
3. ⬜ Transferir para máquina local
4. ⬜ Carregar imagem no Docker local
5. ⬜ Criar repository ECR
6. ⬜ Login ECR na máquina local
7. ⬜ Push para ECR
8. ⬜ Deploy no EKS

**Qual método você prefere? Posso ajudar com qualquer um deles!**

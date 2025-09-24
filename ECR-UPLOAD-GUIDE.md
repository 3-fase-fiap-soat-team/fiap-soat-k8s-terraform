# FIAP SOAT - Guia para Upload de Imagem Docker via Console AWS ECR

## 📋 Informações da Sua Conta
- **Account ID**: 280273007505
- **Region**: us-east-1
- **Imagem Local**: fiap-soat-application-api-dev:latest
- **Tamanho**: 2.24GB

## 🎯 Passo a Passo para Upload via Console AWS

### 1. Acessar o Console ECR
1. Abra o [Console AWS ECR](https://console.aws.amazon.com/ecr/repositories)
2. Certifique-se de estar na região **us-east-1** (N. Virginia)

### 2. Criar Repositório
1. Clique em **"Create repository"**
2. **Repository name**: `fiap-soat-nestjs-app`
3. **Visibility settings**: Private
4. **Image scan settings**: ✅ Scan on push (recomendado)
5. Clique em **"Create repository"**

### 3. Obter Comandos de Push
1. Selecione o repositório criado (`fiap-soat-nestjs-app`)
2. Clique em **"View push commands"**
3. Copie os comandos que aparecerão

### 4. Executar Comandos Localmente

Os comandos serão similares a estes (execute em ordem):

```bash
# 1. Login no ECR (substitua pela região correta)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 280273007505.dkr.ecr.us-east-1.amazonaws.com

# 2. Tag da imagem local
docker tag fiap-soat-application-api-dev:latest 280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest

# 3. Push da imagem
docker push 280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest
```

### 5. Verificar Upload
1. Volte ao console ECR
2. Clique no repositório `fiap-soat-nestjs-app`
3. Você deve ver a imagem com tag `latest`

## 🚀 Após o Upload - Deploy no EKS

Quando a imagem estiver no ECR, execute este comando para fazer deploy:

```bash
cd /home/rafae/fiap-arch-software/fiap-soat-k8s-terraform
./scripts/deploy-from-ecr.sh
```

## 📝 Informações Importantes

- **URI da Imagem ECR**: `280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest`
- **Tamanho**: 2.24GB (pode demorar alguns minutos para upload)
- **Aplicação**: NestJS completa com todas as rotas e funcionalidades

## 🔧 Troubleshooting

### Se o login falhar:
```bash
# Tente com sudo se necessário
sudo aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 280273007505.dkr.ecr.us-east-1.amazonaws.com
```

### Se o push for lento:
- É normal devido ao tamanho da imagem (2.24GB)
- Conexão de rede pode afetar a velocidade
- O console mostrará o progresso

### Se der erro de permissão:
- Certifique-se de usar o console AWS (não CLI) para criar o repositório
- O perfil LabRole tem limitações via CLI, mas console tem acesso completo

## ⚡ Comandos Prontos para Copiar

Abra um terminal e execute:

```bash
# Navegar para diretório da aplicação
cd /home/rafae/fiap-arch-software/fiap-soat-application

# Verificar imagem local
docker images | grep fiap-soat

# Fazer login no ECR (use o comando do console)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 280273007505.dkr.ecr.us-east-1.amazonaws.com

# Tag da imagem
docker tag fiap-soat-application-api-dev:latest 280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest

# Push (pode demorar)
docker push 280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-nestjs-app:latest
```

## 🎉 Próximo Passo

Após o upload bem-sucedido, me avise que criarei o script de deploy automático para usar a imagem ECR no EKS!

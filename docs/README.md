# 📚 Documentação Técnica - FIAP SOAT K8s Terraform

## 🚀 Guias Principais

### Para Começar
- [📘 Setup AWS Academy](AWS-ACADEMY-SETUP.md) - Configure credenciais e workspace AWS
- [🏗️ Deploy EKS + NestJS](nestjs-k8s-setup.md) - Guia completo de implantação

### CI/CD e Automação
- [🔄 Separação CI/CD](CI-CD-SEPARATION.md) - Responsabilidades EKS vs. Application
- [🔐 Gerenciamento de Secrets](SECRETS-MANAGEMENT.md) - Como gerenciar credenciais com segurança
- [🧪 Guia de Testes](TESTING-GUIDE.md) - Passo-a-passo completo de testes

### Kubernetes
- [📦 Guia de Pods](guides/POD-CONCEPTS-GUIDE.md) - Conceitos fundamentais de Pods
- [🔒 Security Groups](guides/SECURITY-GROUPS-GUIDE.md) - Configuração de rede e segurança
- [🌐 Load Balancer](guides/LOAD-BALANCER-GUIDE.md) - NLB vs. ALB, configuração

## 🔍 Troubleshooting

### Problemas Comuns
- [🔧 VPC Discovery](reference/troubleshooting/VPC-DISCOVERY-SOLUTION.md) - Auto-discovery de VPC/Subnets
- [⚙️ ConfigMap](reference/troubleshooting/CONFIGMAP-SOLUTION.md) - Problemas com ConfigMaps
- [🔗 Service Endpoints](reference/troubleshooting/SERVICE-TROUBLESHOOTING.md) - Service sem endpoints
- [🖼️ Image Pull](reference/troubleshooting/IMAGE-PULL-SOLUTION.md) - Erros ao baixar imagens

## 📊 Análises e Referências

### Análises Técnicas
- [📈 Terraform Modules](reference/analysis/TERRAFORM-MODULES-ANALYSIS.md) - Arquitetura dos módulos
- [🗂️ Estrutura do Projeto](reference/analysis/PROJECT-STRUCTURE-ANALYSIS.md) - Organização do código
- [💰 Análise de Custos](reference/analysis/COST-ANALYSIS.md) - Breakdown de custos AWS

### Referências
- [📝 Configuração de Credenciais](reference/AWS-CREDENTIALS-SETUP.md) - Setup de credenciais AWS
- [🎯 Estratégia de Deploy](reference/DEPLOY-STRATEGY.md) - Estratégias de deployment

## 🏛️ Arquivos Históricos

> Documentação antiga mantida para referência histórica (pode ser ignorada para novos desenvolvedores)

- [📁 archived/](archived/) - Guias e análises de iterações anteriores do projeto

## 🎓 Avaliação do Tech Challenge

- [✅ Avaliação do Professor](../AVALIACAO-PROFESSOR.md) - Análise completa do projeto
- [🚀 Prompt de Melhorias](../PROMPT-MELHORIAS.md) - Guia de implementação das correções

## 🧪 Testes

- [📊 Testes de Carga](../load-tests/README.md) - Artillery + K6, scripts automatizados

## 🔗 Repositórios Relacionados

| Repositório | Descrição | Branch Principal |
|-------------|-----------|------------------|
| [fiap-soat-application](https://github.com/3-fase-fiap-soat-team/fiap-soat-application) | Aplicação NestJS (Clean Architecture) | `main` |
| [fiap-soat-lambda](https://github.com/3-fase-fiap-soat-team/fiap-soat-lambda) | Lambdas de autenticação (Cognito) | `feat-rafael` |
| [fiap-soat-database-terraform](https://github.com/3-fase-fiap-soat-team/fiap-soat-database-terraform) | Infraestrutura RDS PostgreSQL | `main` |
| **fiap-soat-k8s-terraform** | **Infraestrutura EKS (este repo)** | **`networking-vpc`** |

## 📖 Como Navegar

### Novo no Projeto?
1. Leia o [README principal](../README.md)
2. Configure o ambiente: [AWS Academy Setup](AWS-ACADEMY-SETUP.md)
3. Deploy inicial: [Deploy EKS](nestjs-k8s-setup.md)
4. Teste o sistema: [Guia de Testes](TESTING-GUIDE.md)

### Problemas?
1. Consulte o [Troubleshooting](#-troubleshooting)
2. Verifique os [logs do workflow](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/actions)
3. Abra uma [issue](https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/issues)

### Contribuindo?
1. Leia a [Separação CI/CD](CI-CD-SEPARATION.md)
2. Entenda o [Gerenciamento de Secrets](SECRETS-MANAGEMENT.md)
3. Siga a estrutura de branches do [README principal](../README.md#-branches-e-repositórios)

---

**Última atualização**: Outubro 2025  
**Maintainers**: Time FIAP SOAT - Fase 3

# 🔄 Separação de Responsabilidades CI/CD

## Problema Resolvido

Anteriormente, **ambos** os workflows (EKS e Application) aplicavam `deployment.yaml`:

- **Workflow EKS**: `kubectl apply -f deployment.yaml` (imagem `:latest`)
- **Workflow Application**: `kubectl set image deployment/... :abc123` (imagem versionada)

**Resultado**: Workflows sobrescreviam um ao outro, causando deploys inconsistentes.

## Solução Implementada

### Workflow EKS (fiap-soat-k8s-terraform)
```yaml
# Aplica APENAS infraestrutura
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl create secret... # Via GitHub Secrets
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
```

### Workflow Application (fiap-soat-application)
```yaml
# Gerencia APENAS deployment
kubectl apply -f k8s/deployment.yaml  # Com imagem versionada
kubectl set image deployment/fiap-soat-application app=...
kubectl rollout status deployment/fiap-soat-application
```

## Manifests por Responsabilidade

| Manifest | Gerenciado Por | Motivo |
|----------|----------------|--------|
| `namespace.yaml` | EKS | Infraestrutura base |
| `configmap.yaml` | EKS | Configurações de ambiente |
| `secret` (via kubectl) | EKS | Credenciais (via GitHub Secrets) |
| `service.yaml` | EKS | Load Balancer (raramente muda) |
| `hpa.yaml` | EKS | Autoscaling (infraestrutura) |
| `deployment.yaml` | **Application** | Imagem muda a cada deploy de código |

## Fluxo de Deploy Completo

### 1. Deploy Inicial (EKS)
```bash
# Provisiona cluster + infraestrutura
terraform apply
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl create secret... # Credenciais
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
```

### 2. Primeiro Deploy da Aplicação
```bash
# Cria deployment com imagem inicial
kubectl apply -f k8s/deployment.yaml
```

### 3. Deploys Subsequentes (Application)
```bash
# Atualiza APENAS imagem do deployment
kubectl set image deployment/fiap-soat-application \
  app=280273007505.dkr.ecr.us-east-1.amazonaws.com/fiap-soat-app:abc123

kubectl rollout status deployment/fiap-soat-application
```

## Vantagens

✅ **Sem Conflitos**: Cada workflow gerencia recursos distintos  
✅ **Versionamento**: Imagem da aplicação sempre com hash do commit  
✅ **Rollback Simples**: `kubectl rollout undo deployment/fiap-soat-application`  
✅ **Deploy Independente**: Atualizar app sem reapply de toda infra  
✅ **Auditoria**: Git history mostra claramente mudanças de infra vs. app

## Troubleshooting

### Problema: Service sem Endpoints
```bash
kubectl get endpoints -n fiap-soat-app
# NAME                           ENDPOINTS   AGE
# fiap-soat-application-service  <none>      10m
```

**Causa**: Deployment ainda não criado (app não deployada)  
**Solução**: Aguardar primeiro deploy da aplicação

### Problema: Imagem Antiga Após Deploy
```bash
kubectl describe pod -n fiap-soat-app | grep Image:
# Image: ...ecr.../fiap-soat-app:latest  ← Deveria ser :abc123
```

**Causa**: Workflow EKS foi executado após workflow Application  
**Solução**: Reexecutar workflow da aplicação

### Problema: HPA não escala
```bash
kubectl get hpa -n fiap-soat-app
# TARGETS: <unknown>/70%
```

**Causa**: Metrics Server não instalado  
**Solução**: 
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

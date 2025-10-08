# 🔐 Gerenciamento de Secrets

## Estratégia de Segurança

### ❌ O que NÃO fazer
- ❌ Commitar secrets em arquivos YAML
- ❌ Usar base64 como "criptografia" (é apenas encoding!)
- ❌ Compartilhar secrets via Slack/Email
- ❌ Usar valores padrão em produção

### ✅ O que fazer
- ✅ Usar **GitHub Secrets** para CI/CD
- ✅ Criar secrets via `kubectl create secret` (nunca `kubectl apply -f`)
- ✅ Rotacionar secrets periodicamente
- ✅ Usar AWS Secrets Manager em produção (futuro)

## Implementação Atual

### 1. GitHub Secrets (CI/CD)

Configure em: `Settings > Secrets and variables > Actions`

| Nome | Descrição | Exemplo |
|------|-----------|---------|
| `DB_PASSWORD` | Senha do RDS PostgreSQL | `SuperSecret123!` |
| `JWT_SECRET` | Secret para assinar JWT | `my-super-secret-key-256-bits` |
| `AWS_ACCESS_KEY_ID` | Credenciais AWS Academy | (renovar a cada 4h) |
| `AWS_SECRET_ACCESS_KEY` | Credenciais AWS Academy | (renovar a cada 4h) |
| `AWS_SESSION_TOKEN` | Token de sessão AWS | (renovar a cada 4h) |

**Workflow cria secret automaticamente**:
```yaml
# .github/workflows/deploy-app.yml
- name: Deploy Kubernetes Manifests
  run: |
    kubectl create secret generic fiap-soat-application-secrets \
      --namespace=fiap-soat-app \
      --from-literal=DATABASE_PASSWORD="${{ secrets.DB_PASSWORD }}" \
      --from-literal=JWT_SECRET="${{ secrets.JWT_SECRET }}" \
      --dry-run=client -o yaml | kubectl apply -f -
```

### 2. Deploy Manual (Desenvolvimento Local)

```bash
# 1. Criar secret manualmente
kubectl create secret generic fiap-soat-application-secrets \
  --namespace=fiap-soat-app \
  --from-literal=DATABASE_PASSWORD='SuperSecret123!' \
  --from-literal=JWT_SECRET='my-super-secret-key-256-bits'

# 2. Verificar (dados ficam ocultos)
kubectl get secret -n fiap-soat-app fiap-soat-application-secrets

# 3. Ver conteúdo (para debug)
kubectl get secret -n fiap-soat-app fiap-soat-application-secrets \
  -o jsonpath='{.data.DATABASE_PASSWORD}' | base64 -d
```

### 3. Usar Template (secret.example.yaml)

```bash
# 1. Copiar template
cp manifests/secret.example.yaml manifests/secret.yaml

# 2. Editar valores
vim manifests/secret.yaml

# 3. Aplicar
kubectl apply -f manifests/secret.yaml

# 4. NUNCA commitar!
# (secret.yaml já está no .gitignore)
```

## ⚠️ IMPORTANTE: Renovação de Credenciais AWS Academy

As credenciais AWS Academy **expiram a cada 4 horas**. Para renovar:

```bash
# 1. Acessar AWS Academy > AWS Details
# 2. Copiar credenciais (Access Key, Secret Key, Session Token)

# 3. Atualizar GitHub Secrets:
# Settings > Secrets > Actions > Update

# OU usar script local:
./scripts/aws-config.sh
```

## Melhorias Futuras (Fase 4)

### AWS Secrets Manager + External Secrets Operator

```yaml
# k8s/external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: fiap-soat-db-credentials
  namespace: fiap-soat-app
spec:
  secretStoreRef:
    name: aws-secrets-manager
  target:
    name: fiap-soat-application-secrets
  data:
    - secretKey: DATABASE_PASSWORD
      remoteRef:
        key: prod/fiap-soat/db-password
```

**Vantagens**:
- 🔄 Rotação automática de secrets
- 📊 Auditoria centralizada (CloudTrail)
- 🔒 Criptografia com AWS KMS
- 🚫 Sem secrets no Git ou GitHub Actions

## Troubleshooting

### Secret não encontrado
```bash
kubectl get secret -n fiap-soat-app
# Error: secrets "fiap-soat-application-secrets" not found
```
**Solução**: Reexecutar workflow ou criar manualmente

### App não consegue ler secret
```bash
kubectl logs -n fiap-soat-app deployment/fiap-soat-application
# Error: DATABASE_PASSWORD environment variable is not set
```
**Solução**: Verificar se deployment.yaml referencia o secret:
```yaml
env:
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: fiap-soat-application-secrets
        key: DATABASE_PASSWORD
```

### Secret com valor errado
```bash
# 1. Atualizar secret
kubectl create secret generic fiap-soat-application-secrets \
  --namespace=fiap-soat-app \
  --from-literal=DATABASE_PASSWORD='NovoValor123!' \
  --dry-run=client -o yaml | kubectl apply -f -

# 2. Reiniciar pods para pegar novo valor
kubectl rollout restart deployment/fiap-soat-application -n fiap-soat-app
```

## Checklist de Segurança

- [ ] `secret.yaml` está no `.gitignore`
- [ ] GitHub Secrets configurados (`DB_PASSWORD`, `JWT_SECRET`)
- [ ] Secrets nunca aparecem em logs
- [ ] Senha do banco tem >12 caracteres
- [ ] JWT secret tem >32 caracteres
- [ ] Credenciais AWS renovadas (< 4h de idade)
- [ ] Sem secrets hardcoded no código

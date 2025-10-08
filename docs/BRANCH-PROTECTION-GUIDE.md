# 🔒 Configuração de Regras de Proteção da Branch Main

## 📋 Passo a Passo

### 1. Acessar Configurações de Branches

1. Acesse: https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/settings/branches
2. Ou navegue: `Settings` > `Branches` > `Branch protection rules`

### 2. Adicionar Regra de Proteção

Clique em **"Add branch protection rule"**

### 3. Configuração Recomendada para Tech Challenge

#### Branch name pattern:
```
main
```

#### Configurações Essenciais:

✅ **Require a pull request before merging**
- [x] Require approvals: **1** (pelo menos 1 aprovação)
- [x] Dismiss stale pull request approvals when new commits are pushed
- [ ] Require review from Code Owners (opcional)

✅ **Require status checks to pass before merging**
- [x] Require branches to be up to date before merging
- Status checks (se houver workflows):
  - [ ] `Terraform EKS` (se existir workflow)
  - [ ] `Deploy Application to EKS` (se existir workflow)

✅ **Require conversation resolution before merging**
- [x] Todos os comentários do PR devem ser resolvidos

✅ **Require linear history**
- [x] Força merge squash ou rebase (sem merge commits)

⚠️ **Do not allow bypassing the above settings**
- [ ] Não marcar (para permitir admin bypass em emergências)

❌ **Não habilitar** (para AWS Academy):
- [ ] ~~Require deployments to succeed~~ (não necessário para dev)
- [ ] ~~Require signed commits~~ (complexo para iniciantes)
- [ ] ~~Lock branch~~ (impede qualquer push)

### 4. Configuração Adicional (Opcional)

#### Rules applied to everyone including administrators:
- [ ] Allow force pushes (DESABILITADO - evita reescrever histórico)
- [ ] Allow deletions (DESABILITADO - protege contra exclusão acidental)

---

## 🎯 Configuração Rápida (Recomendada para Tech Challenge)

Se quiser uma configuração mais simples e ágil:

### Configuração Básica:
```
Branch name pattern: main

✅ Require a pull request before merging
   - Require approvals: 1
   
✅ Require conversation resolution before merging

✅ Do not allow bypassing (deixar DESMARCADO para flexibilidade)
```

Esta configuração garante:
- ✅ Code review obrigatório (1 aprovação)
- ✅ PRs organizados
- ✅ Discussões resolvidas antes do merge
- ✅ Flexibilidade para admins em emergências

---

## 📝 Workflow Recomendado Após Configuração

### 1. Trabalhar em Feature Branch
```bash
# Criar nova branch a partir de main
git checkout main
git pull origin main
git checkout -b feat/nova-feature

# Fazer alterações
git add .
git commit -m "feat: descrição da feature"
git push origin feat/nova-feature
```

### 2. Criar Pull Request
```bash
# Abrir PR no GitHub
gh pr create --base main --head feat/nova-feature \
  --title "feat: Nova Feature" \
  --body "Descrição detalhada da feature"

# OU via browser:
# https://github.com/3-fase-fiap-soat-team/fiap-soat-k8s-terraform/compare/main...feat/nova-feature
```

### 3. Code Review
- Outro membro do time revisa o código
- Resolve comentários
- Aprova o PR

### 4. Merge
- GitHub permite merge após aprovação
- Escolher tipo de merge:
  - **Squash and merge** (recomendado - mantém histórico limpo)
  - Merge commit (mantém todos os commits)
  - Rebase and merge (histórico linear)

---

## 🚨 Merge de `networking-vpc` para `main`

Como você já está na branch `networking-vpc` com as melhorias, precisa:

### Opção 1: Pull Request (Recomendado)
```bash
# 1. Criar PR de networking-vpc para main
gh pr create --base main --head networking-vpc \
  --title "refactor: melhorias técnicas baseadas na avaliação do Tech Challenge" \
  --body "$(cat <<'EOF'
## 📋 Resumo

Implementação das melhorias técnicas identificadas na avaliação do Tech Challenge:

### ✅ Correções Críticas
- Padronização de nomenclatura (fiap-soat-application)
- Separação de responsabilidades CI/CD
- Remoção de secrets hardcoded
- Health checks e resource limits aumentados
- HPA (autoscaling 1-3 replicas)

### 📚 Documentação
- Avaliação do Professor (AVALIACAO-PROFESSOR.md)
- Guia de melhorias (PROMPT-MELHORIAS.md)
- Documentação CI/CD e Secrets
- Guia completo de testes

### 📊 Impacto
- 17 arquivos modificados
- +2833 linhas adicionadas
- Melhoria estimada de 7.8/10 para 8.5+/10

## 🧪 Testes Realizados
- [x] Manifests validados
- [x] README atualizado e testado
- [x] Documentação revisada
- [ ] Workflow CI/CD (pendente teste pós-merge)

## 📝 Checklist
- [x] Código commitado
- [x] Documentação atualizada
- [x] README revisado
- [x] .gitignore atualizado
EOF
)"

# 2. Após aprovação, fazer merge via GitHub UI
```

### Opção 2: Merge Direto (Apenas se for admin e sem proteção ainda)
```bash
# Após configurar proteção, isso NÃO funcionará
git checkout main
git pull origin main
git merge networking-vpc
git push origin main
```

---

## 🎓 Configuração para Outros Repositórios do Time

Replicar as mesmas regras para:

1. **fiap-soat-application**
   - https://github.com/3-fase-fiap-soat-team/fiap-soat-application/settings/branches
   
2. **fiap-soat-lambda**
   - https://github.com/3-fase-fiap-soat-team/fiap-soat-lambda/settings/branches
   
3. **fiap-soat-database-terraform**
   - https://github.com/3-fase-fiap-soat-team/fiap-soat-database-terraform/settings/branches

---

## 💡 Dicas de Boas Práticas

### Nomenclatura de Branches
```
feat/     - Nova funcionalidade
fix/      - Correção de bug
refactor/ - Refatoração de código
docs/     - Apenas documentação
test/     - Testes
chore/    - Tarefas de manutenção
```

### Commits Semânticos
```
feat: adiciona nova feature
fix: corrige bug crítico
refactor: refatora módulo X
docs: atualiza README
test: adiciona testes unitários
chore: atualiza dependências
```

### Code Review Checklist
- [ ] Código segue padrões do projeto
- [ ] Testes passando (se existirem)
- [ ] Documentação atualizada
- [ ] Sem secrets hardcoded
- [ ] Commits bem descritos
- [ ] PR description completa

---

## 📞 Suporte

Dúvidas sobre configuração:
1. Consulte a [documentação do GitHub](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
2. Abra issue no repositório
3. Contate o time no Slack/Discord

---

**Última atualização**: Outubro 2025  
**Autor**: Time FIAP SOAT - Fase 3

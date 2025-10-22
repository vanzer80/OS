# Project Rules — (OS Express - Sistema de Ordens de Serviço)

## Arquitetura e Stack
- API v1 com tratamento consistente de erros/timeouts.
- Frontend com i18n, acessibilidade básica e code-splitting por rota.
- Linters/formatters configurados e no CI.
- SemVer + CHANGELOG automático.

## Dados
- Migrações versionadas; índices para consultas quentes.
- **Supabase/Postgres**: RLS obrigatória em tabelas com dados de usuário; Policies explícitas; roles mínimas; storage rules.
- Timestamps padrão (created_at/updated_at).

## Segurança
- `.env` no `.gitignore`; segredos via CI/CD.
- CORS mínimo; headers de segurança; rate limit em endpoints sensíveis.
- Scanner de dependências em pipeline.

## Testes
- Pirâmide: unit (~70%) > widget (~20%) > integração (~10%).
- Cobertura alvo: geral ≥80%; domínio ≥90%.
- E2E apenas em fluxos críticos; gate no CI.

## CI/CD
- Pipeline: lint → test → build → scan → (e2e) → deploy.
- Artefatos e cache de dependências; rollback definido; staged rollout.

## Observabilidade
- Logs estruturados; métricas básicas; alertas de 5xx/latência.

## Operação
- Ações destrutivas exigem confirmação e rollback.
- Documentação viva (README/ADRs/CHANGELOG).
- Issues/PRs com checklist de aceite e links para ADRs.

# Correções de Erros (CI e Deploy)

Este documento registra os erros observados nas imagens anexadas (GitHub Actions e Vercel) e as correções implementadas.

## 1) GitHub Actions: Falha ao verificar formatação

- **Mensagem Completa**:
  - "Execute `flutter format --set-exit-if-changed`"\n
  - "Não foi possível encontrar um comando chamado 'format'."\n
  - "Execute `flutter -h` (ou `flutter commands -h`) para obter os comandos e opções de flutter disponíveis."\n
  - "Erro: Processo concluído com o código de saída 64."
- **Contexto**: Job `analyze_test_build` do workflow `Flutter CI` em `.github/workflows/ci.yml`, passo "Verifique a formatação".
- **Linha relacionada**:
  - Antes: `run: flutter format --set-exit-if-changed .`
- **Causa**:
  - O subcomando `flutter format` foi descontinuado. A formatação deve ser feita com `dart format`.
- **Correção Aplicada**:
  - Arquivo: `.github/workflows/ci.yml`
  - Alteração: Substituído por `dart format` com flags de CI.
  - Depois: `run: dart format --output none --set-exit-if-changed .`
- **Verificação**:
  - Commit: `6edcc46` em `main` aplica a correção.
  - Um novo pipeline será executado e este passo não deve mais falhar.

## 2) Vercel: Falha no build

- **Mensagem Completa**:
  - `sh: line 1: flutter: command not found`
  - `Error: Command "flutter build web --release" exited with 127`
- **Contexto**: Deploy do projeto "os" na Vercel, região iad1. O ambiente de build da Vercel não possui Flutter por padrão.
- **Causa**:
  - O projeto estava configurado para executar `flutter build web --release` na Vercel, mas Flutter não está disponível no ambiente.
- **Correções Implementadas no Repositório**:
  - Arquivo: `vercel.json`
  - Mudança: Usar `@vercel/static` com arquivos pré-buildados, removendo `installCommand` e `buildCommand`.
  - Além disso, o diretório `build/web` foi versionado (
    exceção no `.gitignore`) e enviado ao `main` para que a Vercel possa servir diretamente os artefatos.
- **Ação necessária na Vercel (Dashboard)**:
  - Settings > Build & Output > Framework: "Other/None"
  - Build Command: vazio (remover qualquer valor)
  - Output Directory: opcional; se usar pelo dashboard, definir `build/web`.
  - Redeploy.
- **Verificação**:
  - Com as mudanças, a Vercel vai ler `vercel.json` e servir `build/web` sem rodar Flutter.

## 3) Considerações adicionais

- O passo "Build web (smoke test)" do CI continua usando `flutter build web --release`, o que é válido no runner do GitHub, pois o `subosito/flutter-action@v2` instala Flutter.
- Na Vercel, evitamos construir Flutter, focando em deploy estático de artefatos já testados localmente.

## Commits relacionados

- `1a55e13` (merge para `main` das configs de deploy e artefatos `build/web`)
- `6edcc46` (corrige formatação no CI para `dart format`)

## Checklist de validação pós-correção

- [ ] GitHub Actions: passo "Check formatting" concluído sem erro
- [ ] GitHub Actions: demais passos analisam e testam conforme esperado
- [ ] Vercel: Settings atualizadas conforme acima
- [ ] Vercel: Deploy de `main` servindo `build/web` corretamente

## Itens que requerem informação/ação externa

- Vercel: Limpar "Build Command" no dashboard do projeto (não pode ser alterado via repositório se estiver sobrescrevendo `vercel.json`).
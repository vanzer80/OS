# Arquitetura de Gestão Financeira

Este documento descreve a arquitetura e implementação das novas funcionalidades de gestão financeira básica, cobrindo backend (Supabase), serviços (Dart/Riverpod) e frontend (Flutter).

## Objetivos
- Registrar e acompanhar receitas (pagamentos) e despesas.
- Expor um diário unificado (ledger) com visão de transações.
- Fornecer resumos mensais e KPIs para o dashboard financeiro.
- Manter compatibilidade com o sistema existente e preparar expansão futura.

## Backend (Supabase)

### Tabelas
- `financial_categories` (por usuário): nome, tipo (`income`/`expense`).
- `expenses` (por usuário): categoria opcional, descrição, valor, data, observação.
- `ledger_entries` (opcional, manual): tipo (`income`/`expense`), referência, valor, data.

Todas com RLS habilitado e políticas por `user_id = auth.uid()`.

### Views
- `finance_ledger_view`: união de `payments` (como receitas) e `expenses` (como despesas).
- `finance_monthly_summary`: agregação por mês (últimos 12) de receitas, despesas e saldo.
- `finance_daily_summary`: agregação diária (últimos 30) de receitas, despesas e saldo.

### Função RPC
- `get_finance_dashboard()`: retorna JSON com `income_month`, `expense_month`, `net_today`, `income_today`, `expense_today`.

### Migrações
- `202510221700_create_finance_tables.sql`
- `202510221701_create_finance_views_functions.sql`

## Serviços (Dart)

Arquivo: `lib/core/finance_service.dart`
- Modelos: `FinanceCategory`, `Expense`, `LedgerItem`, `MonthlyPoint`, `FinanceDashboard`.
- Métodos: `getCategories`, `upsertCategory`, `createExpense`, `getExpenses`, `deleteExpense`, `getLedger`, `getMonthlySummary`, `getDashboard`.
- Providers: `financeServiceProvider`, `financeMonthlySummaryProvider`, `financeDashboardProvider`, `expensesProvider`.

## Frontend (Flutter)

Pastas e telas:
- `lib/features/finance/finance_dashboard_screen.dart`: KPIs e gráfico simples + ações rápidas.
- `lib/features/finance/finance_transactions_screen.dart`: lista unificada de receitas e despesas com filtro de período.
- `lib/features/finance/add_expense_screen.dart`: formulário de nova despesa com seleção/criação de categoria.

### Navegação
- Adicionado novo destino na `NavigationBar`: "Financeiro".
- Lista de telas atualizada em `DashboardScreen` para incluir `FinanceDashboardScreen`.

## Expansibilidade
- Categorias por usuário permitem extensões (ex.: centros de custos, etiquetas).
- `ledger_entries` preparado para integrações futuras (ex.: ajustes manuais, importações).
- Views e RPC podem ser estendidos com mais métricas (ex.: contas a pagar/receber).

## Testes
- `test/finance_service_test.dart`: valida mapeamentos de modelos.
- `test/finance_navigation_test.dart`: valida renderização do dashboard financeiro via overrides de providers.

## Erros e Segurança
- Todas operações validam sessão do usuário via `Supabase.instance.client.auth.currentUser`.
- RLS garante isolamento por usuário nas novas tabelas.
- Tratamento de erros com `SnackBar` no frontend e exceções nos serviços.

## Requisitos
- `supabase_flutter`, `flutter_riverpod`, `intl` já presentes no `pubspec.yaml`.
- Executar migrações no projeto Supabase para disponibilizar as novas estruturas.

## Notas de Implementação
- `finance_ledger_view` depende de `payments` (já existente), mapeando como receitas.
- Em cenários offline, considerar caching local para dados frequentes.
- O gráfico é simples (barras duplas); pode ser substituído por biblioteca especializada futuramente.
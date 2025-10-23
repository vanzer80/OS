-- Views to unify incomes (payments) and expenses, plus summaries

-- Unified ledger view combines payments (income) and expenses
create or replace view public.finance_ledger_view as
select
  p.id as id,
  p.user_id as user_id,
  'income'::text as type,
  p.amount::numeric(12,2) as amount,
  coalesce(p.paid_at::date, p.created_at::date) as entry_date,
  ('Pagamento OS ' || coalesce(p.order_id::text, ''))::text as description
from public.payments p
where p.user_id is not null
union all
select
  e.id,
  e.user_id,
  'expense'::text,
  e.amount::numeric(12,2),
  e.expense_date,
  coalesce(e.description, 'Despesa')
from public.expenses e;

comment on view public.finance_ledger_view is 'Unified ledger of incomes (payments) and expenses';

-- Monthly summary: last 12 months aggregates
create or replace view public.finance_monthly_summary as
select
  date_part('year', entry_date)::int as year,
  date_part('month', entry_date)::int as month,
  sum(case when type = 'income' then amount else 0 end)::numeric(12,2) as income_total,
  sum(case when type = 'expense' then amount else 0 end)::numeric(12,2) as expense_total,
  (sum(case when type = 'income' then amount else 0 end) - sum(case when type = 'expense' then amount else 0 end))::numeric(12,2) as net_total
from public.finance_ledger_view
where entry_date >= (current_date - interval '12 months')
group by 1,2
order by year, month;

comment on view public.finance_monthly_summary is 'Aggregated monthly income, expense and net totals';

-- Daily summary: last 30 days aggregates
create or replace view public.finance_daily_summary as
select
  entry_date,
  sum(case when type = 'income' then amount else 0 end)::numeric(12,2) as income_total,
  sum(case when type = 'expense' then amount else 0 end)::numeric(12,2) as expense_total,
  (sum(case when type = 'income' then amount else 0 end) - sum(case when type = 'expense' then amount else 0 end))::numeric(12,2) as net_total
from public.finance_ledger_view
where entry_date >= (current_date - interval '30 days')
group by 1
order by entry_date;

comment on view public.finance_daily_summary is 'Aggregated daily income, expense and net totals (last 30 days)';

-- RPC: finance dashboard KPIs for current month and today
create or replace function public.get_finance_dashboard()
returns jsonb
language plpgsql
security definer
as $$
declare
  uid uuid := auth.uid();
  this_month_start date := date_trunc('month', current_date)::date;
  income_month numeric(12,2);
  expense_month numeric(12,2);
  net_today numeric(12,2);
  income_today numeric(12,2);
  expense_today numeric(12,2);
begin
  if uid is null then
    return jsonb_build_object('ok', false, 'error', 'not_authenticated');
  end if;

  select coalesce(sum(amount),0) into income_month
    from public.finance_ledger_view
    where user_id = uid and type = 'income' and entry_date >= this_month_start;

  select coalesce(sum(amount),0) into expense_month
    from public.finance_ledger_view
    where user_id = uid and type = 'expense' and entry_date >= this_month_start;

  select coalesce(sum(case when type = 'income' then amount else -amount end),0) into net_today
    from public.finance_ledger_view
    where user_id = uid and entry_date = current_date;

  select coalesce(sum(amount),0) into income_today
    from public.finance_ledger_view where user_id = uid and type = 'income' and entry_date = current_date;

  select coalesce(sum(amount),0) into expense_today
    from public.finance_ledger_view where user_id = uid and type = 'expense' and entry_date = current_date;

  return jsonb_build_object(
    'ok', true,
    'income_month', income_month,
    'expense_month', expense_month,
    'net_today', net_today,
    'income_today', income_today,
    'expense_today', expense_today
  );
end;
$$;

-- Grants for views to ensure PostgREST schema cache exposes them
grant select on public.finance_ledger_view to anon, authenticated;
grant select on public.finance_monthly_summary to anon, authenticated;
grant select on public.finance_daily_summary to anon, authenticated;

-- RPC grant for both anon and authenticated (needed for cache discovery)
grant execute on function public.get_finance_dashboard() to anon, authenticated;

-- Reload PostgREST schema cache to expose new objects immediately
select pg_notify('postgrest', 'reload schema');
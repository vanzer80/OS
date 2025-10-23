-- Apply Finance grants and reload PostgREST schema cache
grant select on public.finance_ledger_view to anon, authenticated;
grant select on public.finance_monthly_summary to anon, authenticated;
grant select on public.finance_daily_summary to anon, authenticated;

grant execute on function public.get_finance_dashboard() to anon, authenticated;

select pg_notify('postgrest', 'reload schema');
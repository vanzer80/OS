-- Create helper function to expose allowed statuses from CHECK constraint
-- Ensures UI can adapt to server schema without hardcoding

create or replace function public.get_allowed_statuses()
returns text[]
language plpgsql
security definer
as $$
declare
  expr text;
  values_text text;
  result text[];
begin
  -- Try to read explicit named constraint first
  select pg_get_expr(c.conbin, c.conrelid)
    into expr
  from pg_constraint c
  join pg_class cl on cl.oid = c.conrelid
  where cl.relname = 'service_orders'
    and c.contype = 'c'
    and (c.conname = 'service_orders_status_check' or c.conname ilike '%status%check%')
  limit 1;

  if expr is null then
    -- Fallback: return a conservative default
    return array['pending','completed','cancelled'];
  end if;

  -- Extract the list inside IN (...) removing quotes and spaces
  -- Works for expressions like: (status = ANY (ARRAY['a','b'])) or status IN ('a','b')
  if expr ilike '%status%IN%' then
    values_text := regexp_replace(expr, '.*status\s*IN\s*\((.*)\).*', '\1');
  elsif expr ilike '%ANY%ARRAY%' then
    values_text := regexp_replace(expr, '.*ARRAY\s*\[(.*)\].*', '\1');
  else
    -- Unknown pattern, return safe default
    return array['pending','completed','cancelled'];
  end if;

  values_text := replace(values_text, '''', '');
  values_text := replace(values_text, ' ', '');
  result := string_to_array(values_text, ',');

  if coalesce(array_length(result, 1), 0) = 0 then
    return array['pending','completed','cancelled'];
  end if;

  return result;
end;
$$;

-- Allow authenticated users to execute (anon can be allowed if desirable)
grant execute on function public.get_allowed_statuses() to authenticated;
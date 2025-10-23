-- Add 'awaiting_part' status to service_orders constraint
-- This adds support for "Aguardando peça" status

-- Drop existing constraint
ALTER TABLE public.service_orders DROP CONSTRAINT IF EXISTS service_orders_status_check;

-- Recreate constraint with new status
ALTER TABLE public.service_orders
  ADD CONSTRAINT service_orders_status_check
  CHECK (status IN (
    'pending',
    'awaiting_approval',
    'awaiting_payment',
    'awaiting_part',
    'in_progress',
    'completed',
    'cancelled'
  ));

-- Update get_allowed_statuses function to include new status in fallback
create or replace function public.get_allowed_statuses()
returns text[]
language plpgsql
security definer
as $$
declare
  expr text;
  result text[];
begin
  -- Try to read the constraint expression
  select pg_get_expr(c.conbin, c.conrelid)
    into expr
  from pg_constraint c
  join pg_class cl on cl.oid = c.conrelid
  where cl.relname = 'service_orders'
    and c.contype = 'c'
    and c.conname = 'service_orders_status_check'
  limit 1;

  -- If constraint not found, return all known statuses including new one
  if expr is null then
    return array['pending','awaiting_approval','awaiting_payment','awaiting_part','in_progress','completed','cancelled'];
  end if;

  -- Parse the constraint to extract status values
  -- Expected format: CHECK (status IN ('pending','awaiting_approval',...))
  if expr ilike '%status%IN%(%' then
    -- Extract content between IN ( and )
    expr := regexp_replace(expr, '.*status\s+IN\s*\(\s*', '');
    expr := regexp_replace(expr, '\s*\).*', '');
    
    -- Remove quotes and split by comma
    expr := replace(expr, '''', '');
    expr := replace(expr, ' ', '');
    result := string_to_array(expr, ',');
    
    -- Filter empty values
    result := array(select unnest(result) where unnest(result) != '');
    
    if array_length(result, 1) > 0 then
      return result;
    end if;
  end if;

  -- Fallback: return all known statuses including new one
  return array['pending','awaiting_approval','awaiting_payment','awaiting_part','in_progress','completed','cancelled'];
end;
$$;

-- Grant execute permissions
grant execute on function public.get_allowed_statuses() to anon, authenticated;

-- Reload PostgREST schema
select pg_notify('postgrest', 'reload schema');
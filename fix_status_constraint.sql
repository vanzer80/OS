-- Fix service_orders status constraint to include awaiting_part
-- Execute this in Supabase SQL Editor

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
CREATE OR REPLACE FUNCTION public.get_allowed_statuses()
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  expr text;
  result text[];
BEGIN
  -- Try to read the constraint expression
  SELECT pg_get_expr(c.conbin, c.conrelid)
    INTO expr
  FROM pg_constraint c
  JOIN pg_class cl ON cl.oid = c.conrelid
  WHERE cl.relname = 'service_orders'
    AND c.contype = 'c'
    AND c.conname = 'service_orders_status_check'
  LIMIT 1;

  -- If constraint not found, return all known statuses including new one
  IF expr IS NULL THEN
    RETURN ARRAY['pending','awaiting_approval','awaiting_payment','awaiting_part','in_progress','completed','cancelled'];
  END IF;

  -- Parse the constraint to extract status values
  -- Expected format: CHECK (status IN ('pending','awaiting_approval',...))
  IF expr ILIKE '%status%IN%(%' THEN
    -- Extract content between IN ( and )
    expr := regexp_replace(expr, '.*status\s+IN\s*\(\s*', '');
    expr := regexp_replace(expr, '\s*\).*', '');
    
    -- Remove quotes and split by comma
    expr := replace(expr, '''', '');
    expr := replace(expr, ' ', '');
    result := string_to_array(expr, ',');
    
    -- Filter empty values
    result := ARRAY(SELECT unnest(result) WHERE unnest(result) != '');
    
    IF array_length(result, 1) > 0 THEN
      RETURN result;
    END IF;
  END IF;

  -- Fallback: return all known statuses including new one
  RETURN ARRAY['pending','awaiting_approval','awaiting_payment','awaiting_part','in_progress','completed','cancelled'];
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_allowed_statuses() TO anon, authenticated;

-- Reload PostgREST schema
SELECT pg_notify('postgrest', 'reload schema');
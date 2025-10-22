-- Remove 'paid' status from service_orders and migrate existing data
-- 1) Update existing rows: map 'paid' to 'completed'
UPDATE public.service_orders SET status = 'completed' WHERE status = 'paid';

-- 2) Recreate status check constraint without 'paid'
ALTER TABLE public.service_orders DROP CONSTRAINT IF EXISTS service_orders_status_check;
ALTER TABLE public.service_orders
  ADD CONSTRAINT service_orders_status_check
  CHECK (status IN (
    'pending',
    'awaiting_approval',
    'awaiting_payment',
    'in_progress',
    'completed',
    'cancelled'
  ));

-- 3) Optional: clean up order_status_audit to normalize legacy entries (non-blocking)
-- UPDATE public.order_status_audit SET new_status = 'completed' WHERE new_status = 'paid';
-- UPDATE public.order_status_audit SET old_status = 'completed' WHERE old_status = 'paid';
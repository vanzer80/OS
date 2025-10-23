-- Create audit table to track status transitions on service_orders
-- Idempotent: creates extension if needed and table with constraints/indexes

-- Ensure UUID generation available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create table
CREATE TABLE IF NOT EXISTS public.order_status_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  user_id UUID NULL,
  old_status TEXT NULL,
  new_status TEXT NOT NULL,
  source TEXT NOT NULL DEFAULT 'admin_function',
  changed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  CONSTRAINT order_status_audit_status_check CHECK (new_status IN (
    'pending',
    'awaiting_approval',
    'awaiting_payment',
    'in_progress',
    'completed',
    'paid',
    'cancelled'
  ))
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_order_status_audit_order_id ON public.order_status_audit(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_audit_user_id ON public.order_status_audit(user_id);
CREATE INDEX IF NOT EXISTS idx_order_status_audit_changed_at ON public.order_status_audit(changed_at);

-- PostgREST schema reload
SELECT pg_notify('postgrest', 'reload schema');
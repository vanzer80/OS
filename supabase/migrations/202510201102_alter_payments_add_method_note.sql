-- Add method_note column to payments for extra method details (e.g., PIX key)
alter table if exists public.payments
  add column if not exists method_note text;

DO $$
BEGIN
  PERFORM pg_notify('pgrst', 'reload schema');
EXCEPTION WHEN others THEN
  NULL;
END $$;
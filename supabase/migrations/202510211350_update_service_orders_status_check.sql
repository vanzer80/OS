-- Atualiza a constraint CHECK de status em service_orders para alinhar com o app
-- Idempotente: derruba a constraint existente se houver e recria com o conjunto completo

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' AND table_name = 'service_orders' AND column_name = 'status'
  ) THEN
    -- Remover constraint antiga, se existir
    IF EXISTS (
      SELECT 1 FROM pg_constraint WHERE conname = 'service_orders_status_check'
    ) THEN
      EXECUTE 'ALTER TABLE public.service_orders DROP CONSTRAINT service_orders_status_check';
    END IF;

    -- Recriar com todos os valores utilizados pelo app
    EXECUTE $$ALTER TABLE public.service_orders
      ADD CONSTRAINT service_orders_status_check
      CHECK (status IN (
        'pending',
        'awaiting_approval',
        'awaiting_payment',
        'in_progress',
        'completed',
        'paid',
        'cancelled'
      ))$$;

    -- Garantir default (opcional)
    EXECUTE 'ALTER TABLE public.service_orders ALTER COLUMN status SET DEFAULT ''pending''';
  END IF;
END $$;

-- Solicitar reload do schema para PostgREST
SELECT pg_notify('postgrest', 'reload schema');
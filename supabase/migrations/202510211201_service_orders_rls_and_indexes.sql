-- service_orders: Habilitar RLS, políticas de dono, índice e unique order_number (idempotente)

-- Habilitar RLS e criar políticas somente se a tabela existir
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'service_orders'
  ) THEN
    -- Habilitar RLS
    EXECUTE 'ALTER TABLE public.service_orders ENABLE ROW LEVEL SECURITY';

    -- Políticas de acesso por dono
    IF NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'public' AND tablename = 'service_orders' AND policyname = 'service_orders_select_owner'
    ) THEN
      EXECUTE 'CREATE POLICY service_orders_select_owner ON public.service_orders FOR SELECT USING (user_id = auth.uid())';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'public' AND tablename = 'service_orders' AND policyname = 'service_orders_insert_owner'
    ) THEN
      EXECUTE 'CREATE POLICY service_orders_insert_owner ON public.service_orders FOR INSERT WITH CHECK (user_id = auth.uid())';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'public' AND tablename = 'service_orders' AND policyname = 'service_orders_update_owner'
    ) THEN
      EXECUTE 'CREATE POLICY service_orders_update_owner ON public.service_orders FOR UPDATE USING (user_id = auth.uid())';
    END IF;

    IF NOT EXISTS (
      SELECT 1 FROM pg_policies 
      WHERE schemaname = 'public' AND tablename = 'service_orders' AND policyname = 'service_orders_delete_owner'
    ) THEN
      EXECUTE 'CREATE POLICY service_orders_delete_owner ON public.service_orders FOR DELETE USING (user_id = auth.uid())';
    END IF;
  END IF;
END $$;

-- Unique constraint em order_number (idempotente)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'service_orders'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_constraint WHERE conname = 'service_orders_order_number_key'
    ) THEN
      EXECUTE 'ALTER TABLE public.service_orders ADD CONSTRAINT service_orders_order_number_key UNIQUE (order_number)';
    END IF;
  END IF;
END $$;

-- Índices comuns (idempotente)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'service_orders'
  ) THEN
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_service_orders_user_id ON public.service_orders(user_id)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_service_orders_status ON public.service_orders(status)';
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_service_orders_created_at ON public.service_orders(created_at)';
  END IF;
END $$;

-- Solicitar reload do schema para PostgREST
SELECT pg_notify('postgrest', 'reload schema');
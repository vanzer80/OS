begin;

-- Colunas padrão do perfil
alter table public.company_profiles add column if not exists default_payment_terms text;
alter table public.company_profiles add column if not exists default_warranty text;

-- Habilitar RLS
alter table public.company_profiles enable row level security;

-- Políticas idempotentes
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'company_profiles'
      AND polname = 'insert own profile'
  ) THEN
    CREATE POLICY "insert own profile"
      ON public.company_profiles
      FOR INSERT
      TO authenticated
      WITH CHECK (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'company_profiles'
      AND polname = 'update own profile'
  ) THEN
    CREATE POLICY "update own profile"
      ON public.company_profiles
      FOR UPDATE
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'company_profiles'
      AND polname = 'select own profile'
  ) THEN
    CREATE POLICY "select own profile"
      ON public.company_profiles
      FOR SELECT
      TO authenticated
      USING (auth.uid() = user_id);
  END IF;
END$$;

-- Atualiza cache do PostgREST
select pg_notify('pgrst', 'reload schema');
commit;
-- Add default columns to company_profiles if they don't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'company_profiles' AND column_name = 'default_payment_terms'
  ) THEN
    ALTER TABLE public.company_profiles ADD COLUMN default_payment_terms text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'company_profiles' AND column_name = 'default_warranty'
  ) THEN
    ALTER TABLE public.company_profiles ADD COLUMN default_warranty text;
  END IF;
END $$;

-- Ensure RLS is enabled (idempotent)
ALTER TABLE public.company_profiles ENABLE ROW LEVEL SECURITY;

-- Ask PostgREST to reload schema cache
DO $$
BEGIN
  PERFORM pg_notify('pgrst', 'reload schema');
EXCEPTION WHEN others THEN
  -- If PostgREST channel isn't present, ignore
  NULL;
END $$;
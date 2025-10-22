-- Tabela auxiliar e função RPC para sequência por ano fiscal

-- Tabela que mantém o próximo número sequencial por ano
CREATE TABLE IF NOT EXISTS public.order_sequences (
  fiscal_year integer PRIMARY KEY,
  next_seq integer NOT NULL DEFAULT 100,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Função com security definer e search_path fixo para evitar problemas de RLS
CREATE OR REPLACE FUNCTION public.get_next_order_seq(fy integer)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_seq integer;
BEGIN
  -- Upsert atômico: cria o ano com 100 ou incrementa em 1
  INSERT INTO public.order_sequences(fiscal_year, next_seq)
  VALUES (fy, 100)
  ON CONFLICT (fiscal_year)
  DO UPDATE SET next_seq = public.order_sequences.next_seq + 1,
                updated_at = now();

  SELECT next_seq INTO v_seq FROM public.order_sequences WHERE fiscal_year = fy;
  RETURN v_seq;
END;
$$;

-- Permitir execução para usuários autenticados
GRANT EXECUTE ON FUNCTION public.get_next_order_seq(integer) TO authenticated;

-- Solicitar reload do schema para PostgREST
SELECT pg_notify('postgrest', 'reload schema');
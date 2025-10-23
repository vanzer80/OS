-- Create documents table to store generated PDFs and related documents per order
create table if not exists public.documents (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  order_id uuid not null references public.service_orders(id) on delete cascade,
  type text not null check (type in ('technical_report','receipt','budget','service','sale')),
  title text,
  file_path text not null,
  mime_type text default 'application/pdf',
  notes text,
  created_at timestamptz not null default now()
);

alter table public.documents enable row level security;

create policy "Documents are viewable by owner" on public.documents
  for select using (auth.uid() = user_id);

create policy "Documents can be inserted by owner" on public.documents
  for insert with check (auth.uid() = user_id);

create policy "Documents can be updated by owner" on public.documents
  for update using (auth.uid() = user_id);

create policy "Documents can be deleted by owner" on public.documents
  for delete using (auth.uid() = user_id);

create index if not exists documents_user_id_idx on public.documents(user_id);
create index if not exists documents_order_id_idx on public.documents(order_id);
create index if not exists documents_type_idx on public.documents(type);

DO $$
BEGIN
  PERFORM pg_notify('pgrst', 'reload schema');
EXCEPTION WHEN others THEN
  NULL;
END $$;
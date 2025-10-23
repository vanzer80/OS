-- Create payment_schedules table to manage planned installments for orders
create table if not exists public.payment_schedules (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  order_id uuid not null references public.service_orders(id) on delete cascade,
  amount numeric(12,2) not null check (amount >= 0),
  due_date date not null,
  paid boolean not null default false,
  paid_at timestamptz,
  payment_id uuid references public.payments(id) on delete set null,
  method text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- RLS
alter table public.payment_schedules enable row level security;

create policy "Payment schedules are viewable by owner" on public.payment_schedules
  for select using (auth.uid() = user_id);

create policy "Payment schedules can be inserted by owner" on public.payment_schedules
  for insert with check (auth.uid() = user_id);

create policy "Payment schedules can be updated by owner" on public.payment_schedules
  for update using (auth.uid() = user_id);

create policy "Payment schedules can be deleted by owner" on public.payment_schedules
  for delete using (auth.uid() = user_id);

-- Indexes
create index if not exists payment_schedules_user_id_idx on public.payment_schedules(user_id);
create index if not exists payment_schedules_order_id_idx on public.payment_schedules(order_id);
create index if not exists payment_schedules_due_date_idx on public.payment_schedules(due_date);
create index if not exists payment_schedules_paid_idx on public.payment_schedules(paid);

-- Update PostgREST cache
DO $$
BEGIN
  PERFORM pg_notify('pgrst', 'reload schema');
EXCEPTION WHEN others THEN
  NULL;
END $$;
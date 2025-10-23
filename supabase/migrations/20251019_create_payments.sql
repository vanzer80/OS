-- Create payments table for recording order payments
create table if not exists public.payments (
  id uuid default gen_random_uuid() primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  order_id uuid not null references public.service_orders(id) on delete cascade,
  amount numeric(12,2) not null check (amount >= 0),
  method text not null default 'pix',
  status text not null default 'paid',
  paid_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.payments enable row level security;

create policy "Payments are viewable by owner" on public.payments
  for select using (auth.uid() = user_id);

create policy "Payments can be inserted by owner" on public.payments
  for insert with check (auth.uid() = user_id);

create policy "Payments can be updated by owner" on public.payments
  for update using (auth.uid() = user_id);

create policy "Payments can be deleted by owner" on public.payments
  for delete using (auth.uid() = user_id);

create index if not exists payments_order_id_idx on public.payments(order_id);
create index if not exists payments_user_id_idx on public.payments(user_id);
create index if not exists payments_paid_at_idx on public.payments(paid_at);
-- Finance tables for basic financial management
-- Categories, Expenses, and an optional manual Ledger table

create table if not exists public.financial_categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  type text not null check (type in ('income','expense')),
  created_at timestamptz not null default now()
);

create index if not exists financial_categories_user_id_idx on public.financial_categories(user_id);
create unique index if not exists financial_categories_user_name_type_uidx on public.financial_categories(user_id, name, type);

comment on table public.financial_categories is 'User-defined categories for incomes and expenses';

create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category_id uuid references public.financial_categories(id) on delete set null,
  description text not null,
  amount numeric(12,2) not null check (amount >= 0),
  expense_date date not null default current_date,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists expenses_user_id_idx on public.expenses(user_id);
create index if not exists expenses_expense_date_idx on public.expenses(expense_date);
create index if not exists expenses_category_id_idx on public.expenses(category_id);

comment on table public.expenses is 'Expense entries for financial management';

-- Optional manual ledger for future expansions (kept minimal for now)
create table if not exists public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('income','expense')),
  ref_table text,
  ref_id uuid,
  amount numeric(12,2) not null check (amount >= 0),
  entry_date date not null default current_date,
  description text,
  created_at timestamptz not null default now()
);

create index if not exists ledger_entries_user_id_idx on public.ledger_entries(user_id);
create index if not exists ledger_entries_entry_date_idx on public.ledger_entries(entry_date);

comment on table public.ledger_entries is 'Manual ledger entries; app will also use views to unify payments and expenses';

-- Row Level Security
alter table public.financial_categories enable row level security;
alter table public.expenses enable row level security;
alter table public.ledger_entries enable row level security;

-- Policies: users can only see and modify their own rows
-- financial_categories
drop policy if exists financial_categories_select on public.financial_categories;
create policy financial_categories_select on public.financial_categories
  for select using (user_id = auth.uid());
drop policy if exists financial_categories_insert on public.financial_categories;
create policy financial_categories_insert on public.financial_categories
  for insert with check (user_id = auth.uid());
drop policy if exists financial_categories_update on public.financial_categories;
create policy financial_categories_update on public.financial_categories
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists financial_categories_delete on public.financial_categories;
create policy financial_categories_delete on public.financial_categories
  for delete using (user_id = auth.uid());

-- expenses
drop policy if exists expenses_select on public.expenses;
create policy expenses_select on public.expenses
  for select using (user_id = auth.uid());
drop policy if exists expenses_insert on public.expenses;
create policy expenses_insert on public.expenses
  for insert with check (user_id = auth.uid());
drop policy if exists expenses_update on public.expenses;
create policy expenses_update on public.expenses
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists expenses_delete on public.expenses;
create policy expenses_delete on public.expenses
  for delete using (user_id = auth.uid());

drop policy if exists ledger_entries_select on public.ledger_entries;
create policy ledger_entries_select on public.ledger_entries
  for select using (user_id = auth.uid());
drop policy if exists ledger_entries_insert on public.ledger_entries;
create policy ledger_entries_insert on public.ledger_entries
  for insert with check (user_id = auth.uid());
drop policy if exists ledger_entries_update on public.ledger_entries;
create policy ledger_entries_update on public.ledger_entries
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists ledger_entries_delete on public.ledger_entries;
create policy ledger_entries_delete on public.ledger_entries
  for delete using (user_id = auth.uid());

-- Grants
grant select, insert, update, delete on public.financial_categories to authenticated;
grant select, insert, update, delete on public.expenses to authenticated;
grant select, insert, update, delete on public.ledger_entries to authenticated;
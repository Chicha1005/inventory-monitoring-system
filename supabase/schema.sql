-- Stockwise inventory database. Run this once in Supabase SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users(id) on delete cascade,
  name text not null default 'My Inventory',
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  sku text not null,
  name text not null,
  principal text not null,
  category text not null default '',
  pieces_per_case numeric(12,3) not null check (pieces_per_case > 0),
  opening_quantity_pieces numeric(14,3) not null default 0 check (opening_quantity_pieces >= 0),
  owning_cost_per_case_vat numeric(14,4) not null default 0 check (owning_cost_per_case_vat >= 0),
  list_price_per_case numeric(14,4) not null default 0 check (list_price_per_case >= 0),
  reorder_level_pieces numeric(14,3) not null default 0 check (reorder_level_pieces >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, sku)
);

create table if not exists public.inventory_entries (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  entry_date date not null,
  mode text not null check (mode in ('DELIVERY RECEIPTS','PHYSICAL COUNT ENDING','PHYSICAL COUNT BEGINNING','PURCHASES','RETURN GOOD STOCKS','BAD ORDER','PICKLIST','STOCK TRANSFER','PURCHASES RETURN','LOADINGS')),
  doc_no text not null default '',
  principal_snapshot text not null,
  sku_snapshot text not null,
  cases numeric(12,3) not null default 0 check (cases >= 0),
  pieces numeric(12,3) not null default 0 check (pieces >= 0),
  pieces_per_case_snapshot numeric(12,3) not null check (pieces_per_case_snapshot > 0),
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now()
);

create index if not exists products_workspace_principal_idx on public.products(workspace_id, principal);
create index if not exists entries_workspace_date_idx on public.inventory_entries(workspace_id, entry_date desc);
create index if not exists entries_product_date_idx on public.inventory_entries(product_id, entry_date desc);

create or replace function public.create_my_workspace(workspace_name text default 'My Inventory')
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare new_id uuid;
begin
  if auth.uid() is null then raise exception 'Sign in required'; end if;
  insert into public.workspaces(owner_id, name)
  values (auth.uid(), coalesce(nullif(trim(workspace_name), ''), 'My Inventory'))
  on conflict (owner_id) do update set owner_id = excluded.owner_id
  returning id into new_id;
  return new_id;
end;
$$;

create or replace function public.touch_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end;
$$;

drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at before update on public.products
for each row execute function public.touch_updated_at();

alter table public.workspaces enable row level security;
alter table public.products enable row level security;
alter table public.inventory_entries enable row level security;

drop policy if exists "owner reads workspace" on public.workspaces;
create policy "owner reads workspace" on public.workspaces for select to authenticated using (owner_id = (select auth.uid()));

drop policy if exists "owner manages products" on public.products;
create policy "owner manages products" on public.products for all to authenticated
using (exists (select 1 from public.workspaces w where w.id = workspace_id and w.owner_id = (select auth.uid())))
with check (exists (select 1 from public.workspaces w where w.id = workspace_id and w.owner_id = (select auth.uid())));

drop policy if exists "owner reads entries" on public.inventory_entries;
create policy "owner reads entries" on public.inventory_entries for select to authenticated
using (exists (select 1 from public.workspaces w where w.id = workspace_id and w.owner_id = (select auth.uid())));
drop policy if exists "owner inserts entries" on public.inventory_entries;
create policy "owner inserts entries" on public.inventory_entries for insert to authenticated
with check (created_by = (select auth.uid()) and exists (select 1 from public.workspaces w where w.id = workspace_id and w.owner_id = (select auth.uid())) and exists (select 1 from public.products p where p.id = inventory_entries.product_id and p.workspace_id = inventory_entries.workspace_id));

revoke all on public.workspaces, public.products, public.inventory_entries from anon;
grant select on public.workspaces to authenticated;
grant select, insert, update, delete on public.products to authenticated;
grant select, insert on public.inventory_entries to authenticated;
revoke all on function public.create_my_workspace(text) from public, anon;
grant execute on function public.create_my_workspace(text) to authenticated;
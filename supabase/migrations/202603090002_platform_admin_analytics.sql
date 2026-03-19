-- Admin + analytics modules for platform tenants.

create table if not exists public.platform_inventory_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.platform_tenants(id) on delete cascade,
  store_id uuid references public.platform_stores(id) on delete cascade,
  item_name text not null,
  sku text,
  unit text not null default 'unit',
  in_stock numeric(12, 2) not null default 0,
  reorder_level numeric(12, 2) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.platform_customer_profiles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.platform_tenants(id) on delete cascade,
  store_id uuid references public.platform_stores(id) on delete cascade,
  phone text not null,
  full_name text,
  tags text[] not null default '{}',
  total_orders int not null default 0,
  lifetime_spend numeric(12, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, phone)
);

create table if not exists public.platform_campaigns (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.platform_tenants(id) on delete cascade,
  store_id uuid references public.platform_stores(id) on delete cascade,
  name text not null,
  channel text not null check (channel in ('push', 'whatsapp', 'sms', 'email', 'in_app')),
  audience_rule jsonb not null default '{}'::jsonb,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'draft' check (status in ('draft', 'scheduled', 'running', 'completed', 'failed')),
  scheduled_for timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.platform_cafe_settings (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.platform_tenants(id) on delete cascade,
  store_id uuid not null references public.platform_stores(id) on delete cascade,
  branding jsonb not null default '{}'::jsonb,
  tax_config jsonb not null default '{}'::jsonb,
  receipt_config jsonb not null default '{}'::jsonb,
  operating_hours jsonb not null default '{}'::jsonb,
  pickup_config jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, store_id)
);

create view public.platform_sales_kpi as
select
  e.tenant_id,
  e.store_id,
  date_trunc('day', e.created_at) as sales_day,
  count(*) filter (where e.action = 'order.created') as order_count,
  0::numeric(12, 2) as gross_revenue
from public.platform_audit_events e
group by e.tenant_id, e.store_id, date_trunc('day', e.created_at);

create index if not exists idx_platform_inventory_tenant_store on public.platform_inventory_items (tenant_id, store_id);
create index if not exists idx_platform_customer_tenant_store on public.platform_customer_profiles (tenant_id, store_id);
create index if not exists idx_platform_campaigns_status on public.platform_campaigns (tenant_id, store_id, status);

alter table public.platform_inventory_items enable row level security;
alter table public.platform_customer_profiles enable row level security;
alter table public.platform_campaigns enable row level security;
alter table public.platform_cafe_settings enable row level security;

drop policy if exists "members read inventory" on public.platform_inventory_items;
create policy "members read inventory"
on public.platform_inventory_items
for select
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_inventory_items.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
  )
);

drop policy if exists "managers manage inventory" on public.platform_inventory_items;
create policy "managers manage inventory"
on public.platform_inventory_items
for all
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_inventory_items.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
)
with check (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_inventory_items.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
);

drop policy if exists "members read customers" on public.platform_customer_profiles;
create policy "members read customers"
on public.platform_customer_profiles
for select
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_customer_profiles.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
  )
);

drop policy if exists "managers manage customers" on public.platform_customer_profiles;
create policy "managers manage customers"
on public.platform_customer_profiles
for all
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_customer_profiles.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
)
with check (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_customer_profiles.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
);

drop policy if exists "members read campaigns" on public.platform_campaigns;
create policy "members read campaigns"
on public.platform_campaigns
for select
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_campaigns.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
  )
);

drop policy if exists "managers manage campaigns" on public.platform_campaigns;
create policy "managers manage campaigns"
on public.platform_campaigns
for all
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_campaigns.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
)
with check (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_campaigns.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
);

drop policy if exists "members read cafe settings" on public.platform_cafe_settings;
create policy "members read cafe settings"
on public.platform_cafe_settings
for select
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_cafe_settings.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
  )
);

drop policy if exists "managers manage cafe settings" on public.platform_cafe_settings;
create policy "managers manage cafe settings"
on public.platform_cafe_settings
for all
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_cafe_settings.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
)
with check (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_cafe_settings.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
);

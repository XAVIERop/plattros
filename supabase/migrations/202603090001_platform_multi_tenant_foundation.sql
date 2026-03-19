-- Multi-tenant platform foundation for Bhursa digital stack.
-- Non-breaking: introduces new platform_* entities without mutating existing cafe_* flows.

create table if not exists public.platform_tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.platform_stores (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.platform_tenants(id) on delete cascade,
  name text not null,
  code text not null,
  timezone text not null default 'Asia/Kolkata',
  currency text not null default 'INR',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, code)
);

create table if not exists public.platform_memberships (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.platform_tenants(id) on delete cascade,
  store_id uuid references public.platform_stores(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('super_admin', 'tenant_admin', 'store_manager', 'cashier', 'kitchen', 'customer')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, store_id, user_id)
);

create table if not exists public.platform_feature_flags (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.platform_tenants(id) on delete cascade,
  store_id uuid references public.platform_stores(id) on delete cascade,
  flag_key text not null,
  flag_value jsonb not null default '{}'::jsonb,
  is_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, store_id, flag_key)
);

create table if not exists public.platform_audit_events (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid references public.platform_tenants(id) on delete cascade,
  store_id uuid references public.platform_stores(id) on delete set null,
  actor_user_id uuid references public.profiles(id) on delete set null,
  action text not null,
  resource_type text not null,
  resource_id text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_platform_stores_tenant_id on public.platform_stores (tenant_id);
create index if not exists idx_platform_memberships_user_id on public.platform_memberships (user_id);
create index if not exists idx_platform_memberships_tenant_store on public.platform_memberships (tenant_id, store_id);
create index if not exists idx_platform_flags_lookup on public.platform_feature_flags (tenant_id, store_id, flag_key);
create index if not exists idx_platform_audit_tenant_created on public.platform_audit_events (tenant_id, created_at desc);

alter table public.platform_tenants enable row level security;
alter table public.platform_stores enable row level security;
alter table public.platform_memberships enable row level security;
alter table public.platform_feature_flags enable row level security;
alter table public.platform_audit_events enable row level security;

drop policy if exists "platform members can read tenant" on public.platform_tenants;
create policy "platform members can read tenant"
on public.platform_tenants
for select
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_tenants.id
      and m.user_id = auth.uid()
      and m.is_active = true
  )
);

drop policy if exists "platform members can read stores" on public.platform_stores;
create policy "platform members can read stores"
on public.platform_stores
for select
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_stores.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and (m.store_id is null or m.store_id = platform_stores.id)
  )
);

drop policy if exists "users can read own memberships" on public.platform_memberships;
create policy "users can read own memberships"
on public.platform_memberships
for select
using (user_id = auth.uid());

drop policy if exists "tenant admin can manage memberships" on public.platform_memberships;
create policy "tenant admin can manage memberships"
on public.platform_memberships
for all
using (
  exists (
    select 1 from public.platform_memberships admin_m
    where admin_m.tenant_id = platform_memberships.tenant_id
      and admin_m.user_id = auth.uid()
      and admin_m.is_active = true
      and admin_m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
)
with check (
  exists (
    select 1 from public.platform_memberships admin_m
    where admin_m.tenant_id = platform_memberships.tenant_id
      and admin_m.user_id = auth.uid()
      and admin_m.is_active = true
      and admin_m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
);

drop policy if exists "tenant admins manage feature flags" on public.platform_feature_flags;
create policy "tenant admins manage feature flags"
on public.platform_feature_flags
for all
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_feature_flags.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
)
with check (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_feature_flags.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin', 'store_manager')
  )
);

drop policy if exists "members can read audit events" on public.platform_audit_events;
create policy "members can read audit events"
on public.platform_audit_events
for select
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_audit_events.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
  )
);

drop policy if exists "services can insert audit events" on public.platform_audit_events;
create policy "services can insert audit events"
on public.platform_audit_events
for insert
with check (auth.role() = 'service_role');

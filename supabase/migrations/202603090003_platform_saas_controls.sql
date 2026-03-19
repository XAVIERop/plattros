-- SaaS platformization: entitlements, provisioning controls, and observability primitives.

create table if not exists public.platform_entitlements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.platform_tenants(id) on delete cascade,
  module_key text not null,
  is_enabled boolean not null default false,
  limits jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, module_key)
);

create table if not exists public.platform_usage_metrics (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.platform_tenants(id) on delete cascade,
  store_id uuid references public.platform_stores(id) on delete cascade,
  metric_key text not null,
  metric_value numeric(18, 4) not null default 0,
  metric_date date not null default current_date,
  created_at timestamptz not null default now(),
  unique (tenant_id, store_id, metric_key, metric_date)
);

create table if not exists public.platform_alerts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.platform_tenants(id) on delete cascade,
  store_id uuid references public.platform_stores(id) on delete cascade,
  severity text not null check (severity in ('info', 'warning', 'critical')),
  source text not null,
  message text not null,
  metadata jsonb not null default '{}'::jsonb,
  is_resolved boolean not null default false,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index if not exists idx_platform_entitlements_tenant on public.platform_entitlements (tenant_id);
create index if not exists idx_platform_usage_tenant_metric on public.platform_usage_metrics (tenant_id, metric_key, metric_date);
create index if not exists idx_platform_alerts_tenant_severity on public.platform_alerts (tenant_id, severity, is_resolved);

alter table public.platform_entitlements enable row level security;
alter table public.platform_usage_metrics enable row level security;
alter table public.platform_alerts enable row level security;

drop policy if exists "members read entitlements" on public.platform_entitlements;
create policy "members read entitlements"
on public.platform_entitlements
for select
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_entitlements.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
  )
);

drop policy if exists "tenant admins manage entitlements" on public.platform_entitlements;
create policy "tenant admins manage entitlements"
on public.platform_entitlements
for all
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_entitlements.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin')
  )
)
with check (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_entitlements.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
      and m.role in ('super_admin', 'tenant_admin')
  )
);

drop policy if exists "members read usage metrics" on public.platform_usage_metrics;
create policy "members read usage metrics"
on public.platform_usage_metrics
for select
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_usage_metrics.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
  )
);

drop policy if exists "services write usage metrics" on public.platform_usage_metrics;
create policy "services write usage metrics"
on public.platform_usage_metrics
for insert
with check (auth.role() = 'service_role');

drop policy if exists "members read alerts" on public.platform_alerts;
create policy "members read alerts"
on public.platform_alerts
for select
using (
  exists (
    select 1 from public.platform_memberships m
    where m.tenant_id = platform_alerts.tenant_id
      and m.user_id = auth.uid()
      and m.is_active = true
  )
);

drop policy if exists "services manage alerts" on public.platform_alerts;
create policy "services manage alerts"
on public.platform_alerts
for all
using (auth.role() = 'service_role')
with check (auth.role() = 'service_role');

create or replace function public.platform_has_entitlement(p_tenant_id uuid, p_module_key text)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.platform_entitlements e
    where e.tenant_id = p_tenant_id
      and e.module_key = p_module_key
      and e.is_enabled = true
  );
$$;

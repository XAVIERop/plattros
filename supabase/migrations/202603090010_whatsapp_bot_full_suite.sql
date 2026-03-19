-- Full-suite WhatsApp bot support: automations, preferences, and event ledger

create table if not exists public.whatsapp_bot_preferences (
  phone text primary key,
  opted_out boolean not null default false,
  quiet_hours_start smallint not null default 22,
  quiet_hours_end smallint not null default 8,
  updated_at timestamptz not null default now()
);

create table if not exists public.whatsapp_bot_events (
  id uuid primary key default gen_random_uuid(),
  event_type text not null,
  phone text,
  cafe_id uuid references public.cafes(id) on delete set null,
  order_id uuid references public.orders(id) on delete set null,
  payload_json jsonb not null default '{}'::jsonb,
  status text not null default 'queued' check (status in ('queued', 'processed', 'skipped', 'failed')),
  error text,
  processed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_whatsapp_bot_events_created_at
  on public.whatsapp_bot_events(created_at desc);

create index if not exists idx_whatsapp_bot_events_phone
  on public.whatsapp_bot_events(phone, created_at desc);

create index if not exists idx_whatsapp_bot_events_order
  on public.whatsapp_bot_events(order_id, created_at desc);

alter table public.whatsapp_sessions
  add column if not exists last_intent text,
  add column if not exists context_json jsonb not null default '{}'::jsonb;

create index if not exists idx_whatsapp_messages_wa_id
  on public.whatsapp_messages(wa_message_id);

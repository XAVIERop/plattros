-- Newsletter signups for Plattr landing page
-- Allows anonymous insert (email only) for lead capture

create table if not exists public.landing_newsletter (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  source text default 'landing_footer',
  created_at timestamptz default now()
);

-- Allow anyone to insert (for signup form)
create policy "Allow anonymous insert for newsletter"
  on public.landing_newsletter
  for insert
  to anon
  with check (true);

-- Enable RLS (anon can only insert; service_role bypasses RLS for admin access)
alter table public.landing_newsletter enable row level security;

-- Index for dedup and lookups
create index if not exists idx_landing_newsletter_email on public.landing_newsletter (email);
create index if not exists idx_landing_newsletter_created_at on public.landing_newsletter (created_at desc);

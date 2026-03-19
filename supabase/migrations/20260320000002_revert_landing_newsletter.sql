-- Revert: Remove landing_newsletter table (if accidentally applied to wrong project)
drop table if exists public.landing_newsletter;

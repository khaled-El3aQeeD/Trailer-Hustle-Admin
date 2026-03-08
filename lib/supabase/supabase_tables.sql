-- Initial schema for TrailerHustle Admin
-- Apply via Dreamflow Supabase module.

-- USERS
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  name text not null default '',
  phone text not null default '',
  avatar_url text not null default '',
  customer_number text unique,
  is_subscribed boolean not null default false,
  is_active boolean not null default true,
  has_hustle_pro_plan boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- GIVEAWAYS
create table if not exists public.giveaways (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  is_draft boolean not null default false,
  scheduled_archive_at timestamptz not null,
  archived_at timestamptz,
  winner_user_id uuid references public.users(id) on delete set null,
  created_by uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_giveaways_scheduled_archive_at on public.giveaways (scheduled_archive_at);

-- GIVEAWAY PARTICIPANTS
create table if not exists public.giveaway_participants (
  id uuid primary key default gen_random_uuid(),
  giveaway_id uuid not null references public.giveaways(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  company_name text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint uq_giveaway_participants_giveaway_user unique (giveaway_id, user_id)
);

create index if not exists idx_giveaway_participants_giveaway_id on public.giveaway_participants (giveaway_id);

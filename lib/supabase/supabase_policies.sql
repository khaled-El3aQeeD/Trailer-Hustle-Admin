-- Row Level Security (RLS) policies for TrailerHustle Admin

-- USERS
alter table public.users enable row level security;

drop policy if exists "users_select_own" on public.users;
create policy "users_select_own" on public.users
for select to authenticated
using (id = auth.uid());

drop policy if exists "users_insert_open" on public.users;
create policy "users_insert_open" on public.users
for insert to authenticated
with check (true);

drop policy if exists "users_update_open" on public.users;
create policy "users_update_open" on public.users
for update to authenticated
using (id = auth.uid())
with check (true);

drop policy if exists "users_delete_own" on public.users;
create policy "users_delete_own" on public.users
for delete to authenticated
using (id = auth.uid());

-- GIVEAWAYS
alter table public.giveaways enable row level security;

drop policy if exists "giveaways_all_authed" on public.giveaways;
create policy "giveaways_all_authed" on public.giveaways
for all to authenticated
using (true)
with check (true);

-- GIVEAWAY PARTICIPANTS
alter table public.giveaway_participants enable row level security;

drop policy if exists "giveaway_participants_all_authed" on public.giveaway_participants;
create policy "giveaway_participants_all_authed" on public.giveaway_participants
for all to authenticated
using (true)
with check (true);

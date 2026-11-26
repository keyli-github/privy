begin;
create table if not exists public.privy_vaults (
  owner uuid primary key references auth.users(id) on delete cascade,
  salt text not null check (length(salt) between 20 and 128),
  wrapped_key text not null check (length(wrapped_key) < 1024),
  payload text not null check (length(payload) <= 16000000),
  revision bigint not null default 0 check (revision >= 0)
);
alter table public.privy_vaults enable row level security;
revoke all on public.privy_vaults from anon, authenticated;
grant select, insert on public.privy_vaults to authenticated;
grant update(payload, revision) on public.privy_vaults to authenticated;
drop policy if exists privy_read on public.privy_vaults;
create policy privy_read on public.privy_vaults for select to authenticated using ((select auth.uid())=owner);
drop policy if exists privy_insert on public.privy_vaults;
create policy privy_insert on public.privy_vaults for insert to authenticated with check ((select auth.uid())=owner and revision=0);
drop policy if exists privy_update on public.privy_vaults;
create policy privy_update on public.privy_vaults for update to authenticated using ((select auth.uid())=owner) with check ((select auth.uid())=owner);
commit;

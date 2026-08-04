-- Supabase dashboard の SQL Editor で一度だけ実行します。

create table if not exists public.focus_entries (
  user_id uuid not null references auth.users(id) on delete cascade,
  id text not null,
  day date not null,
  payload jsonb not null default '{}'::jsonb,
  deleted boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, id)
);

create index if not exists focus_entries_user_day_idx
  on public.focus_entries (user_id, day);

create table if not exists public.focus_drafts (
  user_id uuid not null references auth.users(id) on delete cascade,
  day date not null,
  memo text not null default '',
  task text not null default '',
  updated_at timestamptz not null default now(),
  primary key (user_id, day)
);

create or replace function public.focus_desk_touch_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists focus_entries_touch_updated_at on public.focus_entries;
create trigger focus_entries_touch_updated_at
before update on public.focus_entries
for each row execute function public.focus_desk_touch_updated_at();

drop trigger if exists focus_drafts_touch_updated_at on public.focus_drafts;
create trigger focus_drafts_touch_updated_at
before update on public.focus_drafts
for each row execute function public.focus_desk_touch_updated_at();

alter table public.focus_entries enable row level security;
alter table public.focus_drafts enable row level security;

drop policy if exists "focus_entries_select_own" on public.focus_entries;
create policy "focus_entries_select_own"
on public.focus_entries for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "focus_entries_insert_own" on public.focus_entries;
create policy "focus_entries_insert_own"
on public.focus_entries for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "focus_entries_update_own" on public.focus_entries;
create policy "focus_entries_update_own"
on public.focus_entries for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

drop policy if exists "focus_entries_delete_own" on public.focus_entries;
create policy "focus_entries_delete_own"
on public.focus_entries for delete to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "focus_drafts_select_own" on public.focus_drafts;
create policy "focus_drafts_select_own"
on public.focus_drafts for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "focus_drafts_insert_own" on public.focus_drafts;
create policy "focus_drafts_insert_own"
on public.focus_drafts for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "focus_drafts_update_own" on public.focus_drafts;
create policy "focus_drafts_update_own"
on public.focus_drafts for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.focus_entries to authenticated;
grant select, insert, update on public.focus_drafts to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'focus_entries'
  ) then
    alter publication supabase_realtime add table public.focus_entries;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'focus_drafts'
  ) then
    alter publication supabase_realtime add table public.focus_drafts;
  end if;
end $$;

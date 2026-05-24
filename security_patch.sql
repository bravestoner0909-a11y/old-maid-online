-- Run this once in Supabase SQL Editor before using the patched index.html.
-- This patch adds hashed room passwords, host-only room archive helper, and removes direct room DELETE permission.

create extension if not exists pgcrypto;

alter table if exists public.rooms
  add column if not exists password_hash text;

-- Migrate old plain-text passwords into SHA-256 hashes, then clear the plain text column.
update public.rooms
set password_hash = encode(digest(password_text, 'sha256'), 'hex')
where has_password = true
  and password_hash is null
  and password_text is not null;

update public.rooms
set password_text = null
where password_text is not null;

create or replace function public.delete_room_if_host(p_room_id uuid, p_visitor_id text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  affected_count integer;
begin
  update public.rooms
  set status = 'inactive', updated_at = now()
  where id = p_room_id
    and host_visitor_id = p_visitor_id;

  get diagnostics affected_count = row_count;
  return affected_count > 0;
end;
$$;

grant execute on function public.delete_room_if_host(uuid, text) to anon, authenticated;

-- Basic hardening for the MVP: the browser no longer needs direct room DELETE.
-- Room removal is done by delete_room_if_host(), which checks host_visitor_id.
revoke delete on public.rooms from anon, authenticated;

grant usage on schema public to anon, authenticated;
grant select, insert, update on public.rooms to anon, authenticated;
grant select, insert, update, delete on public.room_players to anon, authenticated;
grant select, insert, update, delete on public.game_state to anon, authenticated;
grant select, insert, update, delete on public.chat_messages to anon, authenticated;
grant select, insert, update, delete on public.votes to anon, authenticated;

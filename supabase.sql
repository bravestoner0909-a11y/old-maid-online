create extension if not exists pgcrypto;

create table if not exists public.rooms (
  id uuid primary key default gen_random_uuid(),
  room_name text not null,
  host_visitor_id text not null,
  max_players int not null check (max_players between 2 and 4),
  has_password boolean not null default false,
  password_text text,
  status text not null default 'waiting' check (status in ('waiting','countdown','playing','finished','inactive')),
  allow_spectators boolean not null default true,
  block_winner_chat boolean not null default false,
  countdown_started_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.room_players (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  visitor_id text not null,
  nickname text not null,
  seat_index int,
  is_host boolean not null default false,
  is_connected boolean not null default true,
  is_spectator boolean not null default false,
  rank int,
  status text not null default 'waiting' check (status in ('waiting','playing','finished','lost','disconnected','spectating')),
  retry_ready boolean not null default false,
  joined_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(room_id, visitor_id)
);

create table if not exists public.game_state (
  room_id uuid primary key references public.rooms(id) on delete cascade,
  state jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  visitor_id text not null,
  nickname text not null,
  message text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.votes (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  vote_type text not null,
  proposed_value boolean not null,
  started_by_visitor_id text not null,
  status text not null default 'active' check (status in ('active','passed','failed','expired')),
  votes_payload jsonb not null default '{}'::jsonb,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists rooms_touch on public.rooms;
create trigger rooms_touch before update on public.rooms for each row execute function public.touch_updated_at();

drop trigger if exists room_players_touch on public.room_players;
create trigger room_players_touch before update on public.room_players for each row execute function public.touch_updated_at();

drop trigger if exists game_state_touch on public.game_state;
create trigger game_state_touch before update on public.game_state for each row execute function public.touch_updated_at();

alter publication supabase_realtime add table public.rooms;
alter publication supabase_realtime add table public.room_players;
alter publication supabase_realtime add table public.game_state;
alter publication supabase_realtime add table public.chat_messages;
alter publication supabase_realtime add table public.votes;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.rooms to anon, authenticated;
grant select, insert, update, delete on public.room_players to anon, authenticated;
grant select, insert, update, delete on public.game_state to anon, authenticated;
grant select, insert, update, delete on public.chat_messages to anon, authenticated;
grant select, insert, update, delete on public.votes to anon, authenticated;

-- MVP speed mode: RLS is intentionally off so the game works immediately.
-- After the MVP works, enable RLS and replace client-side game actions with Edge Functions.
alter table public.rooms disable row level security;
alter table public.room_players disable row level security;
alter table public.game_state disable row level security;
alter table public.chat_messages disable row level security;
alter table public.votes disable row level security;

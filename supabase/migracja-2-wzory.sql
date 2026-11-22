-- Migracja 2: wzory ankiet, własne pytania i kolejność pytań.
-- Uruchomić raz w Supabase: SQL Editor -> New query -> wkleić całość -> Run.

-- Własne pytania i kolejność pytań w ankiecie klienta
alter table public.surveys add column if not exists custom  jsonb not null default '[]';
alter table public.surveys add column if not exists q_order jsonb not null default '{}';

-- Wzory ankiet projektantki
create table if not exists public.templates (
  id         uuid primary key default gen_random_uuid(),
  owner      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name       text not null default '',
  greeting   text not null default '',
  rooms      jsonb not null default '[]',
  off_q      jsonb not null default '[]',
  custom     jsonb not null default '[]',
  q_order    jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.templates enable row level security;
drop policy if exists "projektantka: swoje wzory" on public.templates;
create policy "projektantka: swoje wzory" on public.templates
  for all to authenticated
  using (owner = auth.uid()) with check (owner = auth.uid());
revoke all on public.templates from anon, authenticated;
grant select, insert, update, delete on public.templates to authenticated;

-- Ankieta dla klienta zwraca teraz także własne pytania i kolejność
create or replace function public.get_survey(p_token text)
returns jsonb
language sql stable security definer set search_path = public
as $$
  select jsonb_build_object(
    'client_name', s.client_name,
    'greeting',    s.greeting,
    'plan',        s.plan,
    'rooms',       s.rooms,
    'off_q',       s.off_q,
    'custom',      s.custom,
    'q_order',     s.q_order,
    'status',      s.status,
    'answers',     coalesce(r.answers, '{}'::jsonb),
    'extra',       coalesce(r.extra, '[]'::jsonb),
    'notes',       coalesce(r.notes, '[]'::jsonb),
    'photos',      coalesce((
                     select jsonb_agg(jsonb_build_object('id', p.id, 'field', p.field, 'data', p.data) order by p.created_at)
                     from public.photos p where p.survey_id = s.id
                   ), '[]'::jsonb)
  )
  from public.surveys s
  left join public.responses r on r.survey_id = s.id
  where s.token = p_token;
$$;
revoke all on function public.get_survey(text) from public, anon, authenticated;
grant execute on function public.get_survey(text) to anon, authenticated;

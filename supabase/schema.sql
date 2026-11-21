-- Ankieta wnętrzarska: schemat bazy danych (Supabase)
-- Uruchomić raz w Supabase: SQL Editor -> New query -> wkleić całość -> Run.

-- ============ Tabele ============

-- Ankiety przygotowane przez projektantkę (jedna na klienta)
create table if not exists public.surveys (
  id           uuid primary key default gen_random_uuid(),
  owner        uuid not null default auth.uid() references auth.users(id) on delete cascade,
  token        text not null unique default encode(extensions.gen_random_bytes(12), 'hex'),
  client_name  text not null default '',
  greeting     text not null default '',
  plan         text,                              -- rzut jako obrazek (data URL)
  rooms        jsonb not null default '[]',       -- pomieszczenia oznaczone na rzucie
  off_q        jsonb not null default '[]',       -- wyłączone pytania
  status       text not null default 'nowa' check (status in ('nowa', 'w_trakcie', 'wyslana')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  submitted_at timestamptz
);

-- Odpowiedzi klienta (jedna na ankietę, zapisywana na bieżąco)
create table if not exists public.responses (
  survey_id  uuid primary key references public.surveys(id) on delete cascade,
  answers    jsonb not null default '{}',
  extra      jsonb not null default '[]',         -- pomieszczenia dodane przez klienta
  notes      jsonb not null default '[]',         -- notatki na rzucie
  updated_at timestamptz not null default now()
);

-- Zdjęcia dodane przez klienta
create table if not exists public.photos (
  id         uuid primary key default gen_random_uuid(),
  survey_id  uuid not null references public.surveys(id) on delete cascade,
  field      text not null,                       -- którego pytania dotyczy
  data       text not null,                       -- zdjęcie (data URL)
  created_at timestamptz not null default now()
);
create index if not exists photos_survey_id_idx on public.photos(survey_id);

-- ============ Zabezpieczenia ============
-- Projektantka (zalogowana) widzi i zmienia tylko swoje ankiety.
-- Klient (bez logowania) nie ma dostępu do tabel; korzysta wyłącznie
-- z funkcji poniżej i tylko z ankietą, do której zna link.

alter table public.surveys   enable row level security;
alter table public.responses enable row level security;
alter table public.photos    enable row level security;

drop policy if exists "projektantka: swoje ankiety" on public.surveys;
create policy "projektantka: swoje ankiety" on public.surveys
  for all to authenticated
  using (owner = auth.uid()) with check (owner = auth.uid());

drop policy if exists "projektantka: odpowiedzi do swoich ankiet" on public.responses;
create policy "projektantka: odpowiedzi do swoich ankiet" on public.responses
  for select to authenticated
  using (exists (select 1 from public.surveys s where s.id = survey_id and s.owner = auth.uid()));

drop policy if exists "projektantka: zdjęcia do swoich ankiet" on public.photos;
create policy "projektantka: zdjęcia do swoich ankiet" on public.photos
  for select to authenticated
  using (exists (select 1 from public.surveys s where s.id = survey_id and s.owner = auth.uid()));

revoke all on public.surveys, public.responses, public.photos from anon, authenticated;
grant select, insert, update, delete on public.surveys to authenticated;
grant select on public.responses, public.photos to authenticated;

-- ============ Funkcje dla klienta (dostęp przez link) ============

-- Wczytanie ankiety i dotychczasowych odpowiedzi
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

-- Zapisanie odpowiedzi (na bieżąco albo ostatecznie: p_submit = true)
create or replace function public.save_response(p_token text, p_answers jsonb, p_extra jsonb, p_notes jsonb, p_submit boolean default false)
returns text
language plpgsql security definer set search_path = public
as $$
declare
  v_id uuid;
  v_status text;
begin
  select id into v_id from public.surveys where token = p_token;
  if v_id is null then raise exception 'Nie znaleziono ankiety'; end if;
  if pg_column_size(p_answers) + pg_column_size(p_extra) + pg_column_size(p_notes) > 1000000 then
    raise exception 'Za dużo danych';
  end if;

  insert into public.responses (survey_id, answers, extra, notes, updated_at)
  values (v_id, coalesce(p_answers, '{}'), coalesce(p_extra, '[]'), coalesce(p_notes, '[]'), now())
  on conflict (survey_id) do update
    set answers = excluded.answers, extra = excluded.extra, notes = excluded.notes, updated_at = now();

  update public.surveys
     set status = case when p_submit then 'wyslana' when status = 'nowa' then 'w_trakcie' else status end,
         submitted_at = case when p_submit then now() else submitted_at end,
         updated_at = now()
   where id = v_id
  returning status into v_status;
  return v_status;
end;
$$;

-- Dodanie zdjęcia
create or replace function public.add_photo(p_token text, p_field text, p_data text)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare
  v_id uuid;
  v_new uuid;
begin
  select id into v_id from public.surveys where token = p_token;
  if v_id is null then raise exception 'Nie znaleziono ankiety'; end if;
  if p_data not like 'data:image/%' or length(p_data) > 3000000 then raise exception 'Nieprawidłowe zdjęcie'; end if;
  if (select count(*) from public.photos where survey_id = v_id) >= 60 then raise exception 'Za dużo zdjęć'; end if;
  insert into public.photos (survey_id, field, data) values (v_id, left(p_field, 200), p_data) returning id into v_new;
  return v_new;
end;
$$;

-- Usunięcie zdjęcia
create or replace function public.delete_photo(p_token text, p_id uuid)
returns void
language sql security definer set search_path = public
as $$
  delete from public.photos p
   using public.surveys s
   where p.id = p_id and p.survey_id = s.id and s.token = p_token;
$$;

revoke all on function public.get_survey(text)                                  from public, anon, authenticated;
revoke all on function public.save_response(text, jsonb, jsonb, jsonb, boolean) from public, anon, authenticated;
revoke all on function public.add_photo(text, text, text)                       from public, anon, authenticated;
revoke all on function public.delete_photo(text, uuid)                          from public, anon, authenticated;
grant execute on function public.get_survey(text)                                  to anon, authenticated;
grant execute on function public.save_response(text, jsonb, jsonb, jsonb, boolean) to anon, authenticated;
grant execute on function public.add_photo(text, text, text)                       to anon, authenticated;
grant execute on function public.delete_photo(text, uuid)                          to anon, authenticated;

-- Migracja 3: czyszczenie odpowiedzi klienta przez projektantkę.
-- Uruchomić raz w Supabase: SQL Editor -> New query -> wkleić całość -> Run.

-- Usuwa odpowiedzi i zdjęcia klienta w ankiecie projektantki i przywraca status „nowa”.
create or replace function public.clear_responses(p_survey_id uuid)
returns void
language plpgsql security definer set search_path = public
as $$
begin
  if not exists (select 1 from public.surveys where id = p_survey_id and owner = auth.uid()) then
    raise exception 'Nie znaleziono ankiety';
  end if;
  delete from public.responses where survey_id = p_survey_id;
  delete from public.photos where survey_id = p_survey_id;
  update public.surveys set status = 'nowa', submitted_at = null, updated_at = now() where id = p_survey_id;
end;
$$;
revoke all on function public.clear_responses(uuid) from public, anon, authenticated;
grant execute on function public.clear_responses(uuid) to authenticated;

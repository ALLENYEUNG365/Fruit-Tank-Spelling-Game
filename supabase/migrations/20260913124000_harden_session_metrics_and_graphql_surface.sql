-- Fruit Tank Academy security hardening
-- 1) Sessions are opened server-side and finalized from persisted word attempts.
-- 2) Client-supplied session score/shot/correctness metrics are no longer accepted.
-- 3) Raw word_attempts / word_progress SELECT access is removed from authenticated;
--    teacher analytics and adaptive review use guarded RPCs instead.

create or replace function public.start_my_session(
  p_world text default 'orchard',
  p_mode text default 'Normal'
) returns uuid
language plpgsql
security definer
set search_path=''
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from public.profiles where id=auth.uid() and role='student') then
    raise exception 'Student access required';
  end if;
  insert into public.learning_sessions(
    student_id,world,mode,score,words_completed,shots,correct_attempts,duration_seconds,started_at,ended_at
  ) values (
    auth.uid(),
    coalesce(nullif(trim(p_world),''),'orchard'),
    coalesce(nullif(trim(p_mode),''),'Normal'),
    0,0,0,0,0,now(),null
  ) returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.finish_my_session(p_session_id uuid)
returns public.learning_sessions
language plpgsql
security definer
set search_path=''
as $$
declare
  v_row public.learning_sessions;
  v_shots integer;
  v_correct integer;
  v_words integer;
  v_score integer;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_session_id is null then raise exception 'Session ID is required'; end if;
  if not exists (
    select 1 from public.learning_sessions
    where id=p_session_id and student_id=auth.uid()
  ) then raise exception 'Invalid session'; end if;

  select count(*)::integer,
         count(*) filter (where is_correct)::integer,
         count(distinct word) filter (where is_correct)::integer
    into v_shots,v_correct,v_words
    from public.word_attempts
   where session_id=p_session_id and student_id=auth.uid();

  v_score := greatest(0,v_correct*10);

  update public.learning_sessions
     set shots=v_shots,
         correct_attempts=v_correct,
         words_completed=v_words,
         score=v_score,
         duration_seconds=greatest(0,extract(epoch from (coalesce(ended_at,now())-started_at))::integer),
         ended_at=coalesce(ended_at,now())
   where id=p_session_id and student_id=auth.uid()
  returning * into v_row;

  return v_row;
end;
$$;

revoke execute on function public.start_my_session(text,text) from public,anon;
grant execute on function public.start_my_session(text,text) to authenticated;
revoke execute on function public.finish_my_session(uuid) from public,anon;
grant execute on function public.finish_my_session(uuid) to authenticated;
revoke execute on function public.record_my_session(text,text,integer,integer,integer,integer,integer,timestamptz,timestamptz) from public,anon,authenticated;

revoke select on table public.word_attempts from authenticated;
revoke select on table public.word_progress from authenticated;

revoke execute on function public.complete_my_daily_quest() from public,anon;
grant execute on function public.complete_my_daily_quest() to authenticated;
revoke execute on function public.record_my_word_progress(text,text) from public,anon;
grant execute on function public.record_my_word_progress(text,text) to authenticated;

begin;

-- Security hardening applied to the shared Fruit Tank / English Learning project.
-- This migration is intentionally idempotent so it can reconcile environments
-- that already received the live hardening changes.

-- 1) Limit teacher profile visibility to their own students.
drop policy if exists profiles_select_self_or_teacher on public.profiles;
drop policy if exists profiles_select_self_or_own_class_students on public.profiles;
create policy profiles_select_self_or_own_class_students
on public.profiles
for select
to authenticated
using (
  id = (select auth.uid())
  or exists (
    select 1
    from public.class_memberships cm
    join public.classes c on c.id = cm.class_id
    where cm.student_id = public.profiles.id
      and c.teacher_id = (select auth.uid())
  )
);

-- 2) Anonymous users do not need personal adaptive-review RPCs.
revoke execute on function public.apply_my_review_result(text, boolean, text) from anon;
revoke execute on function public.get_my_adaptive_review(integer) from anon;
revoke execute on function public.get_my_adaptive_review_detail(text) from anon;
revoke execute on function public.get_my_spaced_review_queue(integer) from anon;

-- 3) Keep SECURITY DEFINER functions pinned to an empty search_path.
alter function public.apply_my_review_result(text, boolean, text) set search_path = '';
alter function public.create_my_class(text, text) set search_path = '';
alter function public.ensure_my_profile() set search_path = '';
alter function public.get_my_adaptive_review(integer) set search_path = '';
alter function public.get_my_adaptive_review_detail(text) set search_path = '';
alter function public.get_my_spaced_review_queue(integer) set search_path = '';
alter function public.get_my_teacher_analytics(uuid) set search_path = '';
alter function public.get_my_teacher_attempt_analytics(uuid) set search_path = '';
alter function public.join_class_by_invite(text) set search_path = '';
alter function public.record_my_session(text,text,integer,integer,integer,integer,integer,timestamptz,timestamptz) set search_path = '';
alter function public.record_my_word_attempt(uuid,text,text,text,boolean,text) set search_path = '';
alter function public.remove_student_from_class(uuid,uuid) set search_path = '';
alter function public.sync_my_learning(integer,integer,integer,integer,integer,integer) set search_path = '';
alter function private.handle_new_user() set search_path = '';
alter function private.is_teacher() set search_path = '';
alter function private.prevent_role_escalation() set search_path = '';
alter function private.teacher_of_class(uuid) set search_path = '';

create or replace function public.create_class_invite(p_class_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare v_code text;
begin
 if not exists(select 1 from public.classes where id=p_class_id and teacher_id=(select auth.uid())) then
   raise exception 'Class not found or not owned by teacher';
 end if;
 loop
   v_code='FT-'||upper(substr(encode(extensions.gen_random_bytes(4),'hex'),1,6));
   exit when not exists(select 1 from public.classes where invite_code=v_code);
 end loop;
 update public.classes set invite_code=v_code where id=p_class_id;
 return v_code;
end;
$$;

-- 4) Server-authoritative learning counters. Client-supplied stat values are
-- accepted for API compatibility but never used as authoritative state.
create or replace function public.sync_my_learning(
  p_xp integer,
  p_level integer,
  p_streak integer,
  p_total_words integer,
  p_correct_attempts integer,
  p_total_shots integer
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  p public.profiles;
  v_shots integer;
  v_correct integer;
  v_words integer;
  v_xp integer;
  v_level integer;
  v_streak integer;
begin
  if (select auth.uid()) is null then raise exception 'not authenticated'; end if;
  insert into public.profiles (id, role)
  values ((select auth.uid()), 'student')
  on conflict (id) do nothing;

  select count(*)::integer,
         count(*) filter (where is_correct)::integer,
         count(distinct word) filter (where is_correct)::integer
    into v_shots, v_correct, v_words
    from public.word_attempts
   where student_id=(select auth.uid());

  v_xp := greatest(0, v_correct * 10);
  v_level := greatest(1, floor(v_xp / 100.0)::integer + 1);

  with active_days as (
    select distinct (created_at at time zone 'UTC')::date as d
      from public.word_attempts
     where student_id=(select auth.uid()) and is_correct
  ), latest as (
    select max(d) as last_day from active_days
  ), grouped as (
    select d, d - (row_number() over(order by d))::integer as grp
      from active_days
  ), runs as (
    select grp,count(*)::integer as run_len,max(d) as run_end
      from grouped group by grp
  )
  select case
           when (select last_day from latest) is null then 0
           when (select last_day from latest) >= current_date - 1
             then coalesce((select run_len from runs order by run_end desc limit 1),0)
           else 0
         end
    into v_streak;

  update public.profiles
     set xp=v_xp, level=v_level, streak=greatest(0,v_streak),
         total_words=greatest(0,v_words), correct_attempts=greatest(0,v_correct),
         total_shots=greatest(0,v_shots), updated_at=now()
   where id=(select auth.uid()) and role='student'
  returning * into p;
  return p;
end;
$$;

-- 5) Never trust the browser's is_correct boolean.
create or replace function public.record_my_word_attempt(
  p_session_id uuid,
  p_word text,
  p_target_letter text,
  p_selected_letter text,
  p_is_correct boolean,
  p_world text
)
returns public.word_attempts
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt public.word_attempts;
  v_target text:=upper(trim(coalesce(p_target_letter,'')));
  v_selected text:=upper(trim(coalesce(p_selected_letter,'')));
  v_is_correct boolean;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  if not exists(select 1 from public.profiles where id=(select auth.uid()) and role='student') then
    raise exception 'Student access required';
  end if;
  if coalesce(trim(p_word),'')='' or v_target='' or v_selected='' then
    raise exception 'Word and letters are required';
  end if;
  if p_session_id is not null and not exists(
    select 1 from public.learning_sessions where id=p_session_id and student_id=(select auth.uid())
  ) then raise exception 'Invalid session'; end if;

  v_is_correct := (v_target=v_selected);
  insert into public.word_attempts(student_id,session_id,word,target_letter,selected_letter,is_correct,world)
  values((select auth.uid()),p_session_id,lower(trim(p_word)),v_target,v_selected,v_is_correct,upper(trim(coalesce(p_world,'ORCHARD'))))
  returning * into v_attempt;
  return v_attempt;
end;
$$;

-- 6) Protected write paths for word progress and daily quests.
create or replace function public.record_my_word_progress(p_word text,p_world text default 'orchard')
returns public.word_progress
language plpgsql
security definer
set search_path = ''
as $$
declare v_row public.word_progress;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  if not exists(select 1 from public.profiles where id=(select auth.uid()) and role='student') then raise exception 'Student access required'; end if;
  if coalesce(trim(p_word),'')='' then raise exception 'Word is required'; end if;
  insert into public.word_progress(student_id,word,world,attempts,correct_attempts,mastered,last_attempt_at)
  values((select auth.uid()),lower(trim(p_word)),lower(trim(coalesce(p_world,'orchard'))),1,1,true,now())
  on conflict(student_id,word) do update set
    world=excluded.world,
    attempts=public.word_progress.attempts+1,
    correct_attempts=public.word_progress.correct_attempts+1,
    mastered=true,
    last_attempt_at=now()
  returning * into v_row;
  return v_row;
end;
$$;

create or replace function public.complete_my_daily_quest()
returns public.daily_quests
language plpgsql
security definer
set search_path = ''
as $$
declare v_row public.daily_quests; v_date date:=current_date;
begin
  if (select auth.uid()) is null then raise exception 'Authentication required'; end if;
  if not exists(select 1 from public.profiles where id=(select auth.uid()) and role='student') then raise exception 'Student access required'; end if;
  insert into public.daily_quests(student_id,quest_date,words_completed,target_words,completed)
  values((select auth.uid()),v_date,1,3,false)
  on conflict(student_id,quest_date) do update set
    words_completed=least(public.daily_quests.target_words,public.daily_quests.words_completed+1),
    completed=(least(public.daily_quests.target_words,public.daily_quests.words_completed+1)>=public.daily_quests.target_words)
  returning * into v_row;
  return v_row;
end;
$$;

revoke all on table public.word_progress from authenticated;
grant select on table public.word_progress to authenticated;
revoke all on table public.daily_quests from authenticated;
grant select on table public.daily_quests to authenticated;
revoke insert on table public.learning_sessions from authenticated;
revoke insert on table public.word_attempts from authenticated;
grant execute on function public.record_my_word_progress(text,text) to authenticated;
grant execute on function public.complete_my_daily_quest() to authenticated;
revoke execute on function public.record_my_word_progress(text,text) from anon;
revoke execute on function public.complete_my_daily_quest() from anon;

-- Product ownership documentation without physically moving tables yet.
comment on table public.profiles is 'Shared Core: user profile and learner/teacher summary state.';
comment on table public.classes is 'Shared Core: teacher-owned classroom entities.';
comment on table public.class_memberships is 'Shared Core: student-to-class membership relationships.';
comment on table public.word_progress is 'English Learning: per-student vocabulary progress.';
comment on table public.word_attempts is 'English Learning: vocabulary attempt events and adaptive-review source data.';
comment on table public.learning_mastery is 'English Learning: spaced-repetition mastery state.';
comment on table public.learning_sessions is 'English Learning: learning session analytics.';
comment on table public.daily_quests is 'Fruit Tank: per-student daily game quest state.';
comment on table public.users is 'Legacy/uncategorized: intentionally not exposed through the public API.';
comment on table public.posts is 'Legacy/uncategorized: intentionally not exposed through the public API.';
comment on table public.checkins is 'Legacy/uncategorized: intentionally not exposed through the public API.';

commit;

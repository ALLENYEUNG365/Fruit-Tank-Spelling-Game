-- Server-authoritative word progress.
-- Applied to the active Supabase project as migration 20260913150000.
-- word_progress is now derived from word_attempts inside the trusted attempt RPC.

CREATE OR REPLACE FUNCTION public.record_my_word_attempt(
  p_session_id uuid,
  p_word text,
  p_target_letter text,
  p_selected_letter text,
  p_is_correct boolean,
  p_world text
)
RETURNS public.word_attempts
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
declare
  v_attempt public.word_attempts;
  v_uid uuid := (SELECT auth.uid());
  v_target text := upper(trim(coalesce(p_target_letter,'')));
  v_selected text := upper(trim(coalesce(p_selected_letter,'')));
  v_word text := lower(trim(coalesce(p_word,'')));
  v_world text := lower(trim(coalesce(p_world,'orchard')));
  v_is_correct boolean;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  if not exists(select 1 from public.profiles where id=v_uid and role='student') then
    raise exception 'Student access required';
  end if;
  if v_word='' or length(v_word)>100 or length(v_target)<>1 or length(v_selected)<>1 then
    raise exception 'Word and letters are invalid';
  end if;
  if length(v_world)<1 or length(v_world)>50 then
    raise exception 'World is invalid';
  end if;
  if p_session_id is not null and not exists(
    select 1 from public.learning_sessions where id=p_session_id and student_id=v_uid
  ) then
    raise exception 'Invalid session';
  end if;

  -- Never trust the client-supplied correctness flag.
  v_is_correct := (v_target=v_selected);

  INSERT INTO public.word_attempts(
    student_id,session_id,word,target_letter,selected_letter,is_correct,world
  )
  VALUES(
    v_uid,p_session_id,v_word,v_target,v_selected,v_is_correct,v_world
  )
  RETURNING * INTO v_attempt;

  -- Derive personal word progress from the authoritative attempt just recorded.
  INSERT INTO public.word_progress(
    student_id,word,world,attempts,correct_attempts,mastered,last_attempt_at
  )
  VALUES(
    v_uid,v_word,v_world,1,(case when v_is_correct then 1 else 0 end),v_is_correct,now()
  )
  ON CONFLICT(student_id,word) DO UPDATE SET
    world=excluded.world,
    attempts=public.word_progress.attempts+1,
    correct_attempts=public.word_progress.correct_attempts+excluded.correct_attempts,
    mastered=(public.word_progress.mastered or excluded.mastered),
    last_attempt_at=now();

  RETURN v_attempt;
end;
$function$;

REVOKE EXECUTE ON FUNCTION public.record_my_word_progress(text,text) FROM anon, authenticated;
ALTER FUNCTION public.record_my_word_progress(text,text) SET search_path TO '';

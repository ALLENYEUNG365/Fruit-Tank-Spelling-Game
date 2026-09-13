-- Security hardening for student-facing SECURITY DEFINER learning RPCs.
-- Applied to the active Supabase project as migration 20260913143145.

CREATE OR REPLACE FUNCTION public.apply_my_review_result(p_word text, p_passed boolean, p_world text DEFAULT 'orchard'::text)
RETURNS jsonb LANGUAGE sql SECURITY DEFINER SET search_path TO ''
AS $function$
  WITH me AS (SELECT (SELECT auth.uid()) AS uid),
  normalized AS (
    SELECT lower(trim(coalesce(p_word,''))) AS word,
           lower(trim(coalesce(p_world,'orchard'))) AS world, uid FROM me
  ),
  guard AS (
    SELECT n.* FROM normalized n
    WHERE n.uid IS NOT NULL
      AND length(n.word) BETWEEN 1 AND 100
      AND length(n.world) BETWEEN 1 AND 50
      AND EXISTS (SELECT 1 FROM public.profiles p WHERE p.id=n.uid AND p.role='student')
      AND EXISTS (SELECT 1 FROM public.word_attempts wa WHERE wa.student_id=n.uid AND lower(wa.word)=n.word)
  ),
  old AS (
    SELECT lm.* FROM public.learning_mastery lm JOIN guard g ON g.uid=lm.student_id AND g.word=lm.word
  ),
  vals AS (
    SELECT g.uid,g.word,g.world,p_passed,
      coalesce((SELECT ease_factor FROM old),2.5) ef,
      coalesce((SELECT interval_days FROM old),0) iv,
      coalesce((SELECT repetition_count FROM old),0) rep,
      coalesce((SELECT lapse_count FROM old),0) laps,
      coalesce((SELECT correct_streak FROM old),0) streak,
      coalesce((SELECT total_reviews FROM old),0) reviews,
      coalesce((SELECT correct_reviews FROM old),0) corrects FROM guard g
  ),
  calc AS (
    SELECT *,
      CASE WHEN p_passed THEN least(3.0,ef+0.05) ELSE greatest(1.3,ef-0.2) END nef,
      CASE WHEN p_passed THEN streak+1 ELSE 0 END nstreak,
      CASE WHEN p_passed THEN rep+1 ELSE rep END nrep,
      CASE WHEN p_passed THEN laps ELSE laps+1 END nlaps,
      reviews+1 nreviews,
      CASE WHEN p_passed THEN corrects+1 ELSE corrects END ncorrects,
      CASE WHEN p_passed THEN CASE WHEN rep+1<=1 THEN 1 WHEN rep+1=2 THEN 3 WHEN rep+1=3 THEN 7 WHEN rep+1=4 THEN 14 WHEN rep+1=5 THEN 30 ELSE least(90,round(greatest(1,iv)*ef)::integer) END ELSE 1 END niv
    FROM vals
  ),
  up AS (
    INSERT INTO public.learning_mastery(student_id,word,world,mastery_score,ease_factor,interval_days,repetition_count,lapse_count,correct_streak,total_reviews,correct_reviews,last_reviewed_at,next_review_at,last_error_rate,last_wrong_letter,updated_at)
    SELECT uid,word,world,CASE WHEN p_passed THEN least(100,round(70+least(nstreak,5)*6+nrep*2,2)) ELSE greatest(0,round(45-least(nlaps,5)*5,2)) END,
      nef,niv,nrep,nlaps,nstreak,nreviews,ncorrects,now(),now()+make_interval(days=>niv),CASE WHEN p_passed THEN 0 ELSE 100 END,null,now() FROM calc
    ON CONFLICT(student_id,word) DO UPDATE SET world=excluded.world,mastery_score=excluded.mastery_score,ease_factor=excluded.ease_factor,interval_days=excluded.interval_days,repetition_count=excluded.repetition_count,lapse_count=excluded.lapse_count,correct_streak=excluded.correct_streak,total_reviews=excluded.total_reviews,correct_reviews=excluded.correct_reviews,last_reviewed_at=excluded.last_reviewed_at,next_review_at=excluded.next_review_at,last_error_rate=excluded.last_error_rate,last_wrong_letter=excluded.last_wrong_letter,updated_at=now()
    RETURNING *
  )
  SELECT coalesce((SELECT row_to_json(up)::jsonb FROM up),'{}'::jsonb);
$function$;

CREATE OR REPLACE FUNCTION public.complete_my_daily_quest()
RETURNS public.daily_quests LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
declare v_row public.daily_quests; v_uid uuid := (SELECT auth.uid()); v_date date := current_date; v_completed integer;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  if not exists(select 1 from public.profiles where id=v_uid and role='student') then raise exception 'Student access required'; end if;
  SELECT count(DISTINCT lower(wa.word))::integer INTO v_completed FROM public.word_attempts wa WHERE wa.student_id=v_uid AND wa.is_correct AND (wa.created_at AT TIME ZONE 'UTC')::date=(current_date AT TIME ZONE 'UTC')::date;
  v_completed:=greatest(0,least(3,v_completed));
  INSERT INTO public.daily_quests(student_id,quest_date,words_completed,target_words,completed) VALUES(v_uid,v_date,v_completed,3,v_completed>=3)
  ON CONFLICT(student_id,quest_date) DO UPDATE SET words_completed=EXCLUDED.words_completed,completed=EXCLUDED.completed
  RETURNING * INTO v_row;
  RETURN v_row;
end;
$function$;

CREATE OR REPLACE FUNCTION public.record_my_word_attempt(p_session_id uuid, p_word text, p_target_letter text, p_selected_letter text, p_is_correct boolean, p_world text)
RETURNS public.word_attempts LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
declare v_attempt public.word_attempts; v_uid uuid := (SELECT auth.uid()); v_target text:=upper(trim(coalesce(p_target_letter,''))); v_selected text:=upper(trim(coalesce(p_selected_letter,''))); v_word text:=lower(trim(coalesce(p_word,''))); v_world text:=upper(trim(coalesce(p_world,'ORCHARD'))); v_is_correct boolean;
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  if not exists(select 1 from public.profiles where id=v_uid and role='student') then raise exception 'Student access required'; end if;
  if v_word='' or length(v_word)>100 or length(v_target)<>1 or length(v_selected)<>1 then raise exception 'Word and letters are invalid'; end if;
  if length(v_world)<1 or length(v_world)>50 then raise exception 'World is invalid'; end if;
  if p_session_id is not null and not exists(select 1 from public.learning_sessions where id=p_session_id and student_id=v_uid) then raise exception 'Invalid session'; end if;
  v_is_correct := (v_target=v_selected);
  INSERT INTO public.word_attempts(student_id,session_id,word,target_letter,selected_letter,is_correct,world) VALUES(v_uid,p_session_id,v_word,v_target,v_selected,v_is_correct,v_world) RETURNING * INTO v_attempt;
  RETURN v_attempt;
end;
$function$;

CREATE OR REPLACE FUNCTION public.start_my_session(p_world text DEFAULT 'orchard'::text, p_mode text DEFAULT 'Normal'::text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
declare v_id uuid; v_uid uuid := (SELECT auth.uid()); v_world text:=lower(trim(coalesce(p_world,'orchard'))); v_mode text:=initcap(trim(coalesce(p_mode,'Normal')));
begin
  if v_uid is null then raise exception 'Authentication required'; end if;
  if not exists (select 1 from public.profiles where id=v_uid and role='student') then raise exception 'Student access required'; end if;
  if v_world not in ('orchard','night','sunset') then raise exception 'Invalid world'; end if;
  if v_mode not in ('Easy','Normal','Hard') then raise exception 'Invalid mode'; end if;
  insert into public.learning_sessions(student_id,world,mode,score,words_completed,shots,correct_attempts,duration_seconds,started_at,ended_at) values(v_uid,v_world,v_mode,0,0,0,0,0,now(),null) returning id into v_id;
  return v_id;
end;
$function$;

ALTER FUNCTION public.record_my_word_progress(text,text) SET search_path TO '';

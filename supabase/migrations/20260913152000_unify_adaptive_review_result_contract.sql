-- Unify the Adaptive Review RPC response contract.
-- The database is the source of truth for review quality, mastery,
-- interval and next review date returned to the browser.

CREATE OR REPLACE FUNCTION public.apply_my_review_result(p_word text, p_passed boolean, p_world text DEFAULT 'orchard'::text)
RETURNS jsonb
LANGUAGE sql
SECURITY DEFINER
SET search_path TO ''
AS $function$
  WITH me AS (SELECT (SELECT auth.uid()) AS uid),
  normalized AS (
    SELECT lower(trim(coalesce(p_word,''))) AS word,
           lower(trim(coalesce(p_world,'orchard'))) AS world,
           uid FROM me
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
    SELECT lm.* FROM public.learning_mastery lm
    JOIN guard g ON g.uid=lm.student_id AND g.word=lm.word
  ),
  vals AS (
    SELECT g.uid,g.word,g.world,p_passed,
      coalesce((SELECT ease_factor FROM old),2.5) ef,
      coalesce((SELECT interval_days FROM old),0) iv,
      coalesce((SELECT repetition_count FROM old),0) rep,
      coalesce((SELECT lapse_count FROM old),0) laps,
      coalesce((SELECT correct_streak FROM old),0) streak,
      coalesce((SELECT total_reviews FROM old),0) reviews,
      coalesce((SELECT correct_reviews FROM old),0) corrects
    FROM guard g
  ),
  calc AS (
    SELECT *,
      CASE WHEN p_passed THEN least(3.0,ef+0.05) ELSE greatest(1.3,ef-0.2) END nef,
      CASE WHEN p_passed THEN streak+1 ELSE 0 END nstreak,
      CASE WHEN p_passed THEN rep+1 ELSE rep END nrep,
      CASE WHEN p_passed THEN laps ELSE laps+1 END nlaps,
      reviews+1 nreviews,
      CASE WHEN p_passed THEN corrects+1 ELSE corrects END ncorrects,
      CASE WHEN p_passed THEN CASE WHEN rep+1<=1 THEN 1 WHEN rep+1=2 THEN 3 WHEN rep+1=3 THEN 7 WHEN rep+1=4 THEN 14 WHEN rep+1=5 THEN 30 ELSE least(90,round(greatest(1,iv)*ef)::integer) END ELSE 1 END niv,
      CASE WHEN p_passed THEN 'EXCELLENT'::text ELSE 'NEEDS PRACTICE'::text END quality_label,
      CASE WHEN p_passed THEN 100 ELSE 50 END quality_score
    FROM vals
  ),
  up AS (
    INSERT INTO public.learning_mastery(student_id,word,world,mastery_score,ease_factor,interval_days,repetition_count,lapse_count,correct_streak,total_reviews,correct_reviews,last_reviewed_at,next_review_at,last_error_rate,last_wrong_letter,updated_at)
    SELECT uid,word,world,
      CASE WHEN p_passed THEN least(100,round(70+least(nstreak,5)*6+nrep*2,2)) ELSE greatest(0,round(45-least(nlaps,5)*5,2)) END,
      nef,niv,nrep,nlaps,nstreak,nreviews,ncorrects,now(),now()+make_interval(days=>niv),CASE WHEN p_passed THEN 0 ELSE 100 END,null,now()
    FROM calc
    ON CONFLICT(student_id,word) DO UPDATE SET world=excluded.world,mastery_score=excluded.mastery_score,ease_factor=excluded.ease_factor,interval_days=excluded.interval_days,repetition_count=excluded.repetition_count,lapse_count=excluded.lapse_count,correct_streak=excluded.correct_streak,total_reviews=excluded.total_reviews,correct_reviews=excluded.correct_reviews,last_reviewed_at=excluded.last_reviewed_at,next_review_at=excluded.next_review_at,last_error_rate=excluded.last_error_rate,last_wrong_letter=excluded.last_wrong_letter,updated_at=now()
    RETURNING *
  )
  SELECT coalesce((
    SELECT jsonb_build_object(
      'word',up.word,
      'world',up.world,
      'passed',c.p_passed,
      'quality_label',c.quality_label,
      'quality_score',c.quality_score,
      'mastery_score',up.mastery_score,
      'interval_days',up.interval_days,
      'next_review_at',up.next_review_at,
      'repetition_count',up.repetition_count,
      'lapse_count',up.lapse_count,
      'correct_streak',up.correct_streak,
      'total_reviews',up.total_reviews,
      'correct_reviews',up.correct_reviews,
      'reviewed_at',up.last_reviewed_at
    )
    FROM up CROSS JOIN calc c
  ), '{}'::jsonb);
$function$;

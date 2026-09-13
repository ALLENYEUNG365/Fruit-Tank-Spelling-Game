-- Fruit Tank Academy
-- Repository/production alignment guard.
-- This migration is intentionally idempotent: it verifies the production
-- schema and core RPCs used by the student/teacher flows.

do $$
begin
  if to_regclass('public.profiles') is null
     or to_regclass('public.classes') is null
     or to_regclass('public.class_memberships') is null
     or to_regclass('public.learning_sessions') is null
     or to_regclass('public.word_attempts') is null
     or to_regclass('public.word_progress') is null
     or to_regclass('public.daily_quests') is null
     or to_regclass('public.learning_mastery') is null then
    raise exception 'Fruit Tank Academy schema is incomplete';
  end if;

  if not exists (
    select 1 from pg_proc
    where pronamespace = 'public'::regnamespace
      and proname = 'ensure_my_profile'
  ) then
    raise exception 'Fruit Tank Academy auth RPC ensure_my_profile is missing';
  end if;

  if not exists (
    select 1 from pg_proc
    where pronamespace = 'public'::regnamespace
      and proname = 'record_my_word_attempt'
  ) then
    raise exception 'Fruit Tank Academy learning RPC record_my_word_attempt is missing';
  end if;

  if not exists (
    select 1 from pg_indexes
    where schemaname = 'public'
      and tablename = 'learning_mastery'
      and indexname = 'learning_mastery_due_idx'
  ) then
    create index learning_mastery_due_idx
      on public.learning_mastery (student_id, next_review_at);
  end if;
end
$$;

-- Fruit Tank Academy
-- Supabase dual-role Auth + learning data + RLS
-- Applied to project ref: yxhtshjxvlgswfjhxara

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Cadet',
  role text not null default 'student' check (role in ('student','teacher')),
  avatar_url text,
  level integer not null default 1,
  xp integer not null default 0,
  streak integer not null default 0,
  total_words integer not null default 0,
  correct_attempts integer not null default 0,
  total_shots integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  teacher_id uuid not null references public.profiles(id) on delete restrict,
  school_name text,
  created_at timestamptz not null default now()
);

create table if not exists public.class_memberships (
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.profiles(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (class_id, student_id)
);

create table if not exists public.learning_sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles(id) on delete cascade,
  world text not null default 'orchard',
  mode text not null default 'Normal',
  score integer not null default 0,
  words_completed integer not null default 0,
  shots integer not null default 0,
  correct_attempts integer not null default 0,
  duration_seconds integer not null default 0,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

create table if not exists public.word_attempts (
  id bigint generated always as identity primary key,
  student_id uuid not null references public.profiles(id) on delete cascade,
  session_id uuid references public.learning_sessions(id) on delete set null,
  word text not null,
  target_letter text not null,
  selected_letter text not null,
  is_correct boolean not null,
  world text not null default 'orchard',
  created_at timestamptz not null default now()
);

create table if not exists public.word_progress (
  student_id uuid not null references public.profiles(id) on delete cascade,
  word text not null,
  world text not null default 'orchard',
  attempts integer not null default 0,
  correct_attempts integer not null default 0,
  mastered boolean not null default false,
  last_attempt_at timestamptz not null default now(),
  primary key (student_id, word)
);

create table if not exists public.daily_quests (
  student_id uuid not null references public.profiles(id) on delete cascade,
  quest_date date not null default current_date,
  words_completed integer not null default 0,
  target_words integer not null default 3,
  completed boolean not null default false,
  primary key (student_id, quest_date)
);

-- Teacher promotion is intentionally NOT exposed to the browser.
-- Run from a trusted SQL/admin context after the teacher account exists:
-- update public.profiles set role = 'teacher' where id = '<AUTH_USER_UUID>';

-- RLS principle:
-- students can read/write their own learning rows;
-- teachers can read rows belonging to students in their classes;
-- only trusted admin/service_role code should change profile.role.

-- Document business-domain ownership inside the single shared Supabase project.
-- This migration changes metadata only; it does not change application behavior.

comment on table public.users is 'English Learning domain: owned by AI-GO-Community-English-Learning.';
comment on table public.posts is 'English Learning domain: owned by AI-GO-Community-English-Learning.';
comment on table public.checkins is 'English Learning domain: owned by AI-GO-Community-English-Learning.';

comment on table public.profiles is 'Fruit Tank domain: owned by Fruit-Tank-Spelling-Game.';
comment on table public.classes is 'Fruit Tank domain: owned by Fruit-Tank-Spelling-Game.';
comment on table public.class_memberships is 'Fruit Tank domain: owned by Fruit-Tank-Spelling-Game.';
comment on table public.learning_sessions is 'Fruit Tank domain: owned by Fruit-Tank-Spelling-Game.';
comment on table public.word_attempts is 'Fruit Tank domain: owned by Fruit-Tank-Spelling-Game.';
comment on table public.word_progress is 'Fruit Tank domain: owned by Fruit-Tank-Spelling-Game.';
comment on table public.learning_mastery is 'Fruit Tank domain: owned by Fruit-Tank-Spelling-Game.';
comment on table public.daily_quests is 'Fruit Tank domain: owned by Fruit-Tank-Spelling-Game.';

comment on table public._prisma_migrations is 'English Learning infrastructure metadata for Prisma migrations; shared database infrastructure, not application business data.';

# Fruit Tank Academy — Architecture Diagram

## Executive view

```text
                           ┌───────────────────────────┐
                           │      ADVENTURE ACADEMY    │
                           └─────────────┬─────────────┘
                                         │
                    ┌────────────────────┼────────────────────┐
                    │                    │                    │
                    ▼                    ▼                    ▼
          ┌────────────────┐   ┌────────────────┐   ┌────────────────┐
          │ English        │   │ Fruit Tank     │   │ Shared Core    │
          │ Learning      │   │ Academy        │   │                │
          │                │   │                │   │ Auth           │
          │ Community      │   │ Game           │   │ Security       │
          │ Practice       │   │ Adaptive       │   │ Storage        │
          │ Check-ins      │   │ Review         │   │ Keepalive      │
          └───────┬────────┘   └───────┬────────┘   └───────┬────────┘
                  │                    │                    │
                  └────────────────────┼────────────────────┘
                                       ▼
                         ┌───────────────────────────┐
                         │ Supabase Free             │
                         │ ALLENYEUNG365's Project   │
                         └─────────────┬─────────────┘
                                       │
                 ┌─────────────────────┼─────────────────────┐
                 ▼                     ▼                     ▼
          users/posts/          learning data          shared platform
          checkins              profiles/sessions/     Auth/Storage/etc.
                                attempts/progress
```

## Production request flow

```text
Developer
   │
   ▼
GitHub main
   │
   ▼
Vercel production
   │
   ▼
Browser / Student Portal
   │
   ├──────────────► Supabase Auth
   │
   └──────────────► Guarded RPC / RLS
                          │
                          ▼
                    Fruit Tank tables
```

## Learning data flow

```text
                🎮 GAMEPLAY
                    │
                    ▼
           Start / play / finish
                    │
                    ▼
          learning_sessions
                    │
                    ▼
             word_attempts
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
  word_progress            profile metrics
        │                       │
        └───────────┬───────────┘
                    ▼
          spaced-review queue
                    │
                    ▼
             🧠 REVIEW QUEST
                    │
                    ▼
          mastery / interval /
             next review
                    │
                    ▼
             next learning loop
```

## Security flow

```text
Browser
  │
  │ public browser key only
  ▼
Supabase Auth
  │
  ▼
Authenticated identity
  │
  ▼
RLS + ownership checks
  │
  ▼
Guarded RPC / permitted SELECT
  │
  ▼
Product-owned business data
```

The browser is never trusted to define identity, ownership, or learning-integrity values. The database validates or derives security-sensitive values wherever practical.

## Business-domain ownership

```text
ONE SUPABASE PROJECT
│
├── English Learning
│   ├── users
│   ├── posts
│   └── checkins
│
├── Fruit Tank
│   ├── profiles
│   ├── classes
│   ├── class_memberships
│   ├── learning_sessions
│   ├── word_attempts
│   ├── word_progress
│   ├── learning_mastery
│   └── daily_quests
│
└── Shared Core
    ├── auth.users
    ├── Storage / platform services
    ├── keepalive
    └── shared security / RPC conventions
```

**Principle:** shared infrastructure, isolated business data.

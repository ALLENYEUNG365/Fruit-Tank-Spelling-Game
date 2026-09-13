# Adventure Academy — System Architecture

## 1. Source-of-truth model

Adventure Academy uses three clearly separated layers:

```text
GitHub
  │
  │ canonical source code + database migrations + documentation
  ▼
Vercel
  │
  │ production web delivery
  ▼
Supabase Free — ALLENYEUNG365's Project
  ├── English Learning domain
  ├── Fruit Tank domain
  └── Shared Core
```

### Boundary rules

1. **GitHub is the source of truth for application code.**
   - `main` is the canonical production source.
   - UI, game logic, client configuration, SQL migrations, and documentation belong in GitHub.
   - Production should never become a separate hand-edited copy of the application.

2. **Vercel is the production delivery layer.**
   - Vercel serves the web application and production builds.
   - Vercel does not own application data.
   - Vercel environment variables may contain deployment configuration, but secrets must never be committed to GitHub.

3. **Supabase is the shared backend/data layer.**
   - One Supabase project is intentionally shared by both products.
   - Shared infrastructure does not mean shared business tables.
   - RLS, ownership checks, and guarded RPCs are the security boundary.

## 2. Single Supabase project

Project: `ALLENYEUNG365's Project`

Project ref: `yxhtshjxvlgswfjhxara`

Region: `ap-southeast-1`

The project is deliberately kept as one Free-plan Supabase project. The logical separation is:

```text
Supabase Free
└── ALLENYEUNG365's Project
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
        ├── Supabase Auth
        ├── Storage / platform services
        ├── keepalive
        ├── security/RLS infrastructure
        └── shared RPC conventions
```

## 3. Business-table ownership

### English Learning

The `AI-GO-Community-English-Learning` application owns:

- `users`
- `posts`
- `checkins`

Its Prisma datasource uses `DATABASE_URL` and maps its models to these tables.

### Fruit Tank

The `Fruit-Tank-Spelling-Game` application owns:

- `profiles`
- `classes`
- `class_memberships`
- `learning_sessions`
- `word_attempts`
- `word_progress`
- `learning_mastery`
- `daily_quests`

Fruit Tank database changes are versioned under `supabase/migrations/` and the reference schema is maintained in `supabase/schema.sql`.

### Shared Core

The following are platform/shared concerns rather than product-owned business tables:

- `auth.users`
- Supabase Storage and other platform services
- keepalive infrastructure
- common security/RLS conventions
- shared database RPC patterns

## 4. Runtime responsibility

### Browser

The Fruit Tank static application uses the Supabase **publishable key** only. A publishable key is safe to expose in browser code because authorization is enforced by Supabase Auth, RLS, and guarded database functions.

The browser must never contain:

- a Supabase service-role key
- a database password
- a private API token
- a server-only credential

### Server-side English Learning application

The English Learning application may use its server-side `DATABASE_URL` through Prisma. Database credentials are deployment secrets and must remain outside GitHub source files.

## 5. Data-security boundary

All product data access must follow this order:

```text
Authenticated user
      ↓
Supabase Auth identity
      ↓
RLS / ownership checks
      ↓
Guarded RPC or permitted SELECT
      ↓
Product-owned business tables
```

Client-side JavaScript is never treated as a trusted authority for:

- user identity
- ownership
- score totals
- mastery state
- review correctness
- teacher/student relationships
- privileged writes

Where a value affects learning integrity, the database should derive or validate it server-side.

## 6. Deployment boundary

### Production path

```text
Developer change
      ↓
GitHub main
      ↓
Vercel production deployment
      ↓
Browser
      ↓
Supabase
```

### Important rule

A successful Vercel deployment does **not** become a new source of truth. If production behavior needs to change, change the GitHub source first, then redeploy.

GitHub Pages may remain available as a backup/demo host, but it is not the primary production delivery layer.

## 7. Database migration rule

Database changes follow:

```text
SQL migration in GitHub
        ↓
Review / validation
        ↓
Apply to the single Supabase project
        ↓
Verify schema + security
        ↓
Deploy compatible application code
```

Do not create a second Supabase project merely to separate English Learning and Fruit Tank. Separation is achieved through table ownership, RLS, RPC boundaries, and documentation.

## 8. Naming convention for future tables

Use an explicit product prefix when a future feature could otherwise be ambiguous.

Preferred examples:

- `learning_*` — Fruit Tank learning engine
- `word_*` — Fruit Tank vocabulary/progress data
- `class_*` — Fruit Tank classroom data
- `community_*` or existing `posts` — English Learning community features

Before creating a new table, determine which product owns it and document that ownership.

## 9. Change checklist

Before merging a feature:

- [ ] Code change is committed to GitHub.
- [ ] No production secrets are committed.
- [ ] The correct Supabase business tables are used.
- [ ] RLS/ownership is checked for new data access.
- [ ] Privileged writes use guarded server-side functions/RPCs where appropriate.
- [ ] Database migrations are stored in GitHub.
- [ ] Vercel production deployment uses the intended GitHub source.
- [ ] Existing English Learning tables are not reused for Fruit Tank business data unless explicitly designed as shared infrastructure.

---

**Architecture principle:** one backend project, two isolated business domains, one canonical source repository per product, and one production delivery layer through Vercel.

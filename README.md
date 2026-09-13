# 🍓 Fruit Tank Academy

> **Shoot letters. Spell fruit. Learn English.**

Fruit Tank Academy is an Adventure Academy-style gamified English learning experience built around spelling practice, adaptive review, learner progress, and classroom-ready cloud data.

## 🎮 Production Site

**Primary production host:**

👉 https://fruit-tank-academy.vercel.app/

**Canonical source code:**

👉 https://github.com/ALLENYEUNG365/Fruit-Tank-Spelling-Game

GitHub is the source of truth. Vercel is the production delivery layer. GitHub Pages may remain as a backup/demo host and is not the primary production endpoint.

## 🏗️ System Architecture

```text
                    Adventure Academy
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
       GitHub            Vercel         Supabase Free
       Source            Delivery       ALLENYEUNG365's Project
          │                │                │
          │                │        ┌───────┴────────┐
          │                │        ▼                ▼
          │                │   English Learning   Fruit Tank
          │                │   users/posts/       profiles/classes/
          │                │   checkins           learning/progress
          │                │
          └────── canonical code + migrations ──────┘
```

### Three-layer boundary

| Layer | Responsibility | Must NOT own |
|---|---|---|
| **GitHub** | Source code, migrations, documentation, version history | Production runtime state or secrets |
| **Vercel** | Web hosting, builds, production delivery | Business data or database credentials in source |
| **Supabase** | Auth, database, storage/platform services, guarded RPCs | UI/source-code ownership |

The complete boundary contract is documented in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## ☁️ One Supabase Project — Two Business Domains

We intentionally use **one Supabase Free project**, not separate projects.

```text
ALLENYEUNG365's Project
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
    ├── Supabase Auth
    ├── Storage / platform services
    ├── keepalive
    └── shared security / RPC conventions
```

**Shared infrastructure ≠ shared business tables.** Each product owns its own business data. RLS, ownership checks, and guarded RPCs provide the runtime security boundary.

## 🔐 Security Boundary

Browser code uses the Supabase **publishable key** only. It must never contain service-role keys, database passwords, or other server-only credentials.

The application follows:

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

Client JavaScript is not treated as a trusted authority for identity, ownership, learning integrity, mastery, scores, or privileged writes.

## 🎮 Game Features

- **Order-based spelling:** shoot the next correct letter in sequence.
- **Tank controls:** keyboard and on-screen controls support movement and firing.
- **Difficulty modes:** Easy, Normal and Hard provide different time limits.
- **Scoring:** correctly completed words award points.
- **Immediate feedback:** correct, incorrect, firing and success interactions provide visual/audio feedback.
- **Replayability:** start, pause, skip and reset controls support repeated practice.
- **Adaptive review:** personalized review queues use learner progress data.
- **Cloud progress:** authenticated learning sessions, attempts, progress and quests can be synchronized with Supabase.
- **Responsive experience:** designed for desktop and mobile interaction.

## 🧠 Educational Learning Loop

```text
See the fruit
      ↓
Identify the target word
      ↓
Recall the spelling
      ↓
Move the tank & shoot letters
      ↓
Build the word in correct order
      ↓
Immediate visual + audio feedback
      ↓
Record learning evidence
      ↓
Adaptive review / reinforcement
      ↓
Return to the next quest
```

The design turns passive spelling recall into a short action-feedback-repetition loop.

## ⏱️ Difficulty Modes

| Mode | Time per word | Learning use |
|---|---:|---|
| Easy | 60 seconds | First exposure / beginners |
| Normal | 40 seconds | Regular practice |
| Hard | 20 seconds | Retrieval-speed challenge |

## 🕹️ How to Play

1. Start a round and identify the fruit shown.
2. Read the blank word pattern.
3. Move the tank and fire at the correct next letter.
4. Continue until the whole word is completed in order.
5. Review feedback and progress, then continue the adventure.

**Keyboard:** `←` `→` to move, `Space` to fire.

## 🧩 Vocabulary Theme

The current game uses fruit vocabulary such as:

**apple · banana · orange · grape · peach · pear · mango · lemon · cherry · strawberry**

## 🛠️ Technology

- HTML5 / CSS3
- Vanilla JavaScript
- HTML Canvas
- Web Audio API
- Supabase Auth + PostgreSQL
- Supabase RPC / RLS security model
- Vercel production delivery
- GitHub source control and migration history

## 📁 Repository Structure

```text
Fruit-Tank-Spelling-Game/
├── index.html
├── auth.html
├── student-portal.html
├── game.html
├── game-core.html
├── adaptive-review.html
├── dashboard.html
├── teacher-insights.html
├── cloud-sync-v2.js
├── supabase/
│   ├── schema.sql
│   └── migrations/
├── docs/
│   └── ARCHITECTURE.md
└── README.md
```

## 🚀 Deployment Rules

```text
Change source
    ↓
GitHub main
    ↓
Vercel production build
    ↓
Production site
    ↓
Supabase shared backend
```

A production deployment is never a replacement for the GitHub source. Database changes must also be represented by migrations in GitHub before or alongside deployment.

## 🎥 Demo Video

Watch the project demonstration:

👉 https://drive.google.com/file/d/1fmcqtiN3TkzxEL1e2xWSemmgIUEpHkj-/view?usp=sharing

## 👤 Creator

**Allen Yeung**

Education · Digital Technology · AI & Cloud Learning

Interested in building practical technology-enhanced learning experiences that combine interaction, multimedia and real educational outcomes.

## 🔗 Project Links

- 🎮 **Production:** https://fruit-tank-academy.vercel.app/
- 💻 **GitHub:** https://github.com/ALLENYEUNG365/Fruit-Tank-Spelling-Game
- 🎥 **Demo Video:** https://drive.google.com/file/d/1fmcqtiN3TkzxEL1e2xWSemmgIUEpHkj-/view?usp=sharing

---

### From assignment to educational product

**Fruit Tank Academy** is presented as an independent educational product concept: a playable example of how interaction design, adaptive learning, cloud progress tracking, and game mechanics can work together in language education.

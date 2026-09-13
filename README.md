# 🍓 Fruit Tank Academy

> **Shoot letters. Spell fruit. Learn English.**
>
> A gamified English spelling platform that turns vocabulary practice into an interactive adventure with adaptive review, learner analytics, and cloud-based progress tracking.

[![Live Demo](https://img.shields.io/badge/Live%20Demo-Fruit%20Tank%20Academy-1f6feb?style=for-the-badge)](https://fruit-tank-academy.vercel.app/)
[![GitHub](https://img.shields.io/badge/Source-GitHub-181717?style=for-the-badge&logo=github)](https://github.com/ALLENYEUNG365/Fruit-Tank-Spelling-Game)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ecf8e?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![Vercel](https://img.shields.io/badge/Deployment-Vercel-000000?style=for-the-badge&logo=vercel)](https://vercel.com/)

## 🚀 What is Fruit Tank Academy?

**Fruit Tank Academy** is an educational game platform designed around one simple idea: make English spelling feel like a short adventure rather than a worksheet.

Learners identify fruit vocabulary, build each word by shooting the correct letters in sequence, receive immediate feedback, and generate learning evidence that feeds a personalized review system.

The project combines:

- 🎮 game-based spelling practice
- 🧠 adaptive and spaced review
- ☁️ authenticated cloud learning records
- 📊 learner progress and classroom-oriented data
- 🔐 RLS and guarded RPC-based backend security
- 📱 responsive desktop and mobile interaction

The result is a small but complete **learning-product architecture**, not just a game demo.

---

## 🎯 Product Vision

Fruit Tank Academy sits inside a larger **Adventure Academy** concept:

```text
                    ADVENTURE ACADEMY
                           │
               ┌───────────┴───────────┐
               │                       │
        English Learning          Fruit Tank Academy
               │                       │
        Community + practice     Game + adaptive review
               │                       │
               └───────────┬───────────┘
                           ▼
                    Shared Learning Core
                    Auth · Security · Data
```

The products share infrastructure while keeping their business data logically separated.

---

## 🧠 The Learning Loop

```text
Discover vocabulary
       ↓
See the target word
       ↓
Recall the spelling
       ↓
Move the tank
       ↓
Shoot letters in order
       ↓
Immediate feedback
       ↓
Record learning evidence
       ↓
Adaptive review
       ↓
Spaced reinforcement
       ↓
Return to the next quest
```

This converts a passive spelling task into a short **action → feedback → reflection → repetition** cycle.

---

## 🎮 Core Gameplay

### Order-based spelling

Each word is completed letter-by-letter. The learner must identify the next correct letter rather than simply selecting the complete word.

### Tank-based interaction

The learner controls a small tank and fires at letter targets, creating a physical game mechanic around spelling retrieval.

### Difficulty modes

| Mode | Time per word | Learning purpose |
|---|---:|---|
| Easy | 60 seconds | First exposure and confidence building |
| Normal | 40 seconds | Regular retrieval practice |
| Hard | 20 seconds | Faster recall and fluency challenge |

### Immediate feedback

The game provides visual and audio feedback for correct letters, mistakes, firing, and completed words.

### Replayability

Rounds can be repeated so learners can practice the same vocabulary multiple times while cloud progress continues to accumulate.

---

## 🧠 Adaptive Review System

The game is connected to a dedicated **Review Quest** experience.

```text
Fruit Tank gameplay
        ↓
word_attempts
        ↓
word_progress
        ↓
learning evidence
        ↓
spaced-review queue
        ↓
Review Quest
        ↓
mastery + interval + next review
```

Review Quest ranks learning targets using signals such as:

- recent errors
- wrong-letter patterns
- mastery level
- review due time
- previous review performance
- lapses / repeated difficulty

The learner can then complete a focused spelling drill and receive a new mastery / review schedule.

---

## ☁️ Cloud Learning Architecture

Fruit Tank intentionally uses a **single Supabase Free project** shared with the wider Adventure Academy ecosystem.

```text
ALLENYEUNG365's Supabase Project
│
├── English Learning domain
│   ├── users
│   ├── posts
│   └── checkins
│
├── Fruit Tank domain
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

### Shared infrastructure ≠ shared business tables

The English Learning product and Fruit Tank own separate business tables. They share only the infrastructure and conventions that should actually be shared.

This allows the project to scale as a product family without collapsing unrelated business logic into one schema.

---

## 🔐 Security by Design

The browser never receives a service-role key, database password, or other server-only credential.

The runtime authorization model is:

```text
Authenticated user
      ↓
Supabase Auth identity
      ↓
RLS / ownership checks
      ↓
Guarded RPC or permitted SELECT
      ↓
Product-owned learning tables
```

### Important integrity rules

- Row Level Security is enabled on the core learning tables.
- Privileged writes are routed through guarded database functions/RPCs.
- The server recalculates letter correctness instead of trusting the client-supplied correctness flag.
- Session ownership is validated before learning records are written.
- SECURITY DEFINER functions use a locked-down `search_path` convention.
- Service-role credentials are never committed to the repository.

The detailed boundary contract is documented in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## 🏗️ Production Architecture

```text
                 GitHub
            Canonical source
                   │
                   ▼
                 Vercel
           Production delivery
                   │
                   ▼
            Browser application
                   │
          ┌────────┴────────┐
          │                 │
          ▼                 ▼
   Supabase Auth      Guarded RPC / RLS
                            │
                            ▼
                   Fruit Tank data layer
```

### Source-of-truth rules

- **GitHub** owns source code, migrations, documentation, and version history.
- **Vercel** owns production web delivery.
- **Supabase** owns authentication, database services, and learning records.

A production deployment is always the delivery of GitHub source; it is not a replacement source of truth.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| Game UI | HTML5, CSS3, Vanilla JavaScript |
| Rendering | HTML Canvas |
| Audio | Web Audio API |
| Authentication | Supabase Auth |
| Database | Supabase PostgreSQL |
| Data security | RLS + guarded RPCs |
| Hosting | Vercel |
| Source control | GitHub |
| Learning model | Adaptive review + spaced reinforcement |

No heavy game framework is required. The project stays intentionally lightweight so the learning logic remains visible and easy to audit.

---

## 🧩 Vocabulary

The current fruit vocabulary set includes examples such as:

**apple · banana · orange · grape · peach · pear · mango · lemon · cherry · strawberry**

The vocabulary layer can be expanded without redesigning the learning architecture.

---

## 🕹️ How to Play

1. Start a mission.
2. Identify the target fruit word.
3. Move the tank into position.
4. Fire at the correct next letter.
5. Complete the whole word in sequence.
6. Continue the quest and review your learning data afterward.

### Controls

**Keyboard**

- `←` / `→` — move
- `Space` — fire / hold to auto-fire

**Mobile**

- on-screen movement and fire controls

---

## 📊 Learning Data Model

Fruit Tank records evidence at multiple levels:

```text
Profile
  ├── XP / level / streak
  ├── total words
  └── accuracy metrics

Session
  ├── world
  ├── difficulty mode
  ├── score
  ├── words completed
  └── duration

Word Attempt
  ├── target letter
  ├── selected letter
  ├── correctness
  ├── session
  └── world

Word Progress
  ├── attempts
  ├── correct attempts
  ├── mastery state
  └── last attempt

Review
  ├── quality
  ├── mastery
  ├── interval
  └── next review time
```

This structure makes the game useful as a learning system because gameplay produces reusable evidence rather than one-off scores.

---

## 📁 Repository Map

```text
Fruit-Tank-Spelling-Game/
├── index.html                 # public entry
├── auth.html                  # authentication
├── student-portal.html        # learner hub
├── play.html                  # authenticated game launcher
├── game.html                  # compatibility route
├── game-core.html             # core game runtime
├── adaptive-review.html       # personalized review quest
├── dashboard.html             # learner/analytics surface
├── teacher-insights.html      # teacher-oriented insights
├── supabase-config.js         # centralized client configuration
├── cloud-sync-core.js         # non-blocking game/cloud bridge
├── supabase/
│   ├── schema.sql
│   └── migrations/
├── docs/
│   └── ARCHITECTURE.md
└── README.md
```

---

## 🚀 Live Product

### Production

👉 **https://fruit-tank-academy.vercel.app/**

### Source

👉 **https://github.com/ALLENYEUNG365/Fruit-Tank-Spelling-Game**

### Demo video

👉 https://drive.google.com/file/d/1fmcqtiN3TkzxEL1e2xWSemmgIUEpHkj-/view?usp=sharing

---

## 💡 Why This Project Matters

Fruit Tank Academy began as a game-learning experiment and has evolved into a small educational product prototype with:

- a playable interaction model
- a cloud-backed learner identity
- persistent learning records
- adaptive review
- a security-aware backend design
- a clear product boundary between game and learning services

The project demonstrates how **game mechanics, learning science, cloud architecture, and application security** can be combined into one deployable learning experience.

---

## 👤 Creator

**Allen Yeung**  
Education · Digital Technology · AI & Cloud Learning

The project focuses on building practical, technology-enhanced learning experiences that connect interaction design with measurable educational outcomes.

---

## 📌 Project Status

**Active product prototype / portfolio project**

The core gameplay, authentication, cloud progress synchronization, and adaptive review loop are implemented and deployed. Future work can expand the vocabulary library, classroom tooling, analytics, teacher workflows, and more advanced server-authoritative review logic.

---

## 📄 License

No license file is currently included in this repository. All rights reserved unless otherwise stated by the repository owner.

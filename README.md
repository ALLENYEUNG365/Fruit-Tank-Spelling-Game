# 🍓 Fruit Tank Academy

> **Shoot letters. Spell fruit. Learn English.**
>
> A gamified English learning platform that combines interactive spelling practice, adaptive review, spaced reinforcement, learning analytics, and cloud-based learner progress into one adventure-driven experience.

<p align="center">
  <a href="https://fruit-tank-academy-p8dlqmq8g-allen-yeungs-projects.vercel.app/"><strong>🎮 PLAY LIVE</strong></a> ·
  <a href="https://github.com/ALLENYEUNG365/Fruit-Tank-Spelling-Game"><strong>💻 SOURCE CODE</strong></a>
</p>

![GitHub stars](https://img.shields.io/github/stars/ALLENYEUNG365/Fruit-Tank-Spelling-Game?style=flat-square)
![GitHub last commit](https://img.shields.io/github/last-commit/ALLENYEUNG365/Fruit-Tank-Spelling-Game?style=flat-square)
![Vercel](https://img.shields.io/badge/Production-Vercel-000000?style=flat-square&logo=vercel)
![Supabase](https://img.shields.io/badge/Backend-Supabase-3ecf8e?style=flat-square&logo=supabase&logoColor=white)
![JavaScript](https://img.shields.io/badge/JavaScript-Vanilla-F7DF1E?style=flat-square&logo=javascript&logoColor=111)

> **Portfolio positioning:** Fruit Tank Academy is presented as a deployable EdTech product prototype—not only a browser game. The repository demonstrates the connection between gameplay, learning evidence, adaptive review, cloud data, and security-aware application architecture.

---

## ✨ Product at a glance

| | |
|---|---|
| 🎮 **Game-Based Learning** | Spell fruit vocabulary by moving a tank and shooting letters in sequence. |
| 🧠 **Adaptive Review** | Missed or review-due vocabulary is surfaced in a focused Review Quest. |
| ☁️ **Cloud Learning Data** | Authenticated sessions, attempts, progress, quests, and learner metrics sync to Supabase. |
| 🔐 **Security by Design** | RLS, ownership checks, and guarded RPCs protect learning data and privileged writes. |
| 📊 **Learning Evidence** | Gameplay produces structured evidence that can feed mastery and spaced-review logic. |
| 📱 **Responsive** | Designed for desktop keyboard play and mobile on-screen controls. |

---

## 🖼️ Product Screenshots

> **Screenshot placeholders are intentional.** Replace the placeholders below with your latest production screenshots when ready.

### 🎮 Main Game

`[SCREENSHOT PLACEHOLDER — Fruit Tank gameplay: tank, fruit target, letter enemies, score/time HUD]`

### 🧠 Review Quest

`[SCREENSHOT PLACEHOLDER — Adaptive Review page showing review queue, mastery, next review, and focused drill]`

### 👤 Student Academy / Portal

`[SCREENSHOT PLACEHOLDER — Student portal showing learner progress and Academy navigation]`

### 📊 Teacher / Analytics View

`[SCREENSHOT PLACEHOLDER — Teacher insights / analytics dashboard]`

---

## 🎥 Demo Video

**Replace this link with the latest demo recording when ready:**

👉 `[NEW DEMO VIDEO LINK — INSERT HERE]`

The repository can use a direct video link, Google Drive share link, YouTube link, or other public demo URL.

---

## 🧭 Architecture at a glance

```text
                           ADVENTURE ACADEMY
                                  │
             ┌────────────────────┼────────────────────┐
             │                    │                    │
             ▼                    ▼                    ▼
      English Learning      Fruit Tank Academy     Shared Core
      community + practice  game + adaptive review  Auth / security
             │                    │                    │
             └────────────────────┼────────────────────┘
                                  ▼
                    ALLENYEUNG365's Supabase
                         single Free project
```

### Production data flow

```text
                    🎮 Fruit Tank gameplay
                              │
                              ▼
                     learning_sessions
                              │
                     ┌────────┴────────┐
                     ▼                 ▼
               word_attempts      profile metrics
                     │                 │
                     ▼                 ▼
               word_progress       learner state
                     │
                     ▼
            spaced-review queue / RPC
                     │
                     ▼
                🧠 Review Quest
                     │
                     ▼
          mastery → interval → next review
```

### Deployment boundary

```text
Developer change
      ↓
GitHub main
      ↓
Vercel production
      ↓
Browser
      ↓
Supabase Auth / RPC / RLS
      ↓
Fruit Tank learning data
```

For the full architecture and business-data ownership model, see [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## 🧠 Learning loop

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

The goal is to turn passive spelling recall into a short **action → feedback → reflection → repetition** cycle.

---

## 🎮 Gameplay

### Order-based spelling

Learners complete each word letter-by-letter. The target sequence matters, so the task measures retrieval rather than simple whole-word recognition.

### Tank-based interaction

A lightweight tank mechanic adds movement, timing, and targeting to spelling practice.

### Difficulty modes

| Mode | Time per word | Learning use |
|---|---:|---|
| Easy | 60 seconds | First exposure / confidence building |
| Normal | 40 seconds | Regular retrieval practice |
| Hard | 20 seconds | Faster recall challenge |

### Controls

**Desktop:** `←` / `→` to move, `Space` to fire or hold to auto-fire.

**Mobile:** on-screen movement and fire controls.

---

## 🧠 Adaptive Review Quest

The game is connected to a dedicated review experience so gameplay can continue into targeted practice.

```text
Game attempt
    ↓
word_attempts
    ↓
word_progress
    ↓
review queue
    ↓
Focused drill
    ↓
mastery / interval / next review
```

The current queue can use signals including:

- recent mistakes
- wrong-letter patterns
- mastery level
- review due time
- repeated difficulty / lapses
- previous review performance

The learner can then practice a selected word again without leaving the Academy flow.

---

## ☁️ Cloud architecture

Fruit Tank intentionally shares one Supabase Free project with the wider Adventure Academy ecosystem while maintaining strict business-domain separation.

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

> **Shared infrastructure ≠ shared business tables.**

The English Learning and Fruit Tank products share platform infrastructure, but each product owns its own business data.

---

## 🔐 Security model

The browser uses a public Supabase browser key; it never contains service-role credentials or database passwords.

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

Core protections include:

- Row Level Security on business data
- ownership checks inside guarded functions
- server-side recalculation of letter correctness
- session ownership validation
- locked-down `search_path` for SECURITY DEFINER functions
- no service-role key in browser code

Detailed architecture and security boundaries are documented in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## 🗃️ Learning data model

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

Gameplay therefore creates reusable learning evidence rather than a one-off game score.

---

## 🧩 Vocabulary

The current fruit vocabulary includes examples such as:

**apple · banana · orange · grape · peach · pear · mango · lemon · cherry · strawberry**

The vocabulary layer can expand without redesigning the underlying learning architecture.

---

## 🛠️ Technology stack

| Layer | Technology |
|---|---|
| Game UI | HTML5, CSS3, Vanilla JavaScript |
| Rendering | HTML Canvas |
| Audio | Web Audio API |
| Authentication | Supabase Auth |
| Database | Supabase PostgreSQL |
| Security | RLS + guarded RPCs |
| Hosting | Vercel |
| Source | GitHub |
| Learning model | Adaptive review + spaced reinforcement |

The project intentionally stays lightweight so the game loop and learning logic remain visible and auditable.

---

## 📁 Repository map

```text
Fruit-Tank-Spelling-Game/
├── index.html                 # public entry
├── auth.html                  # authentication
├── student-portal.html        # learner hub
├── play.html                  # authenticated game launcher
├── game.html                  # compatibility route
├── game-core.html             # core game runtime
├── adaptive-review.html       # personalized review quest
├── dashboard.html             # learner / analytics surface
├── teacher-insights.html      # teacher-oriented insights
├── supabase-config.js         # centralized browser config
├── cloud-sync-core.js         # non-blocking game/cloud bridge
├── supabase/
│   ├── schema.sql
│   └── migrations/
├── docs/
│   └── ARCHITECTURE.md
└── README.md
```

---

## 🚀 Live product

### Production

👉 **https://fruit-tank-academy-p8dlqmq8g-allen-yeungs-projects.vercel.app/**

### GitHub

👉 **https://github.com/ALLENYEUNG365/Fruit-Tank-Spelling-Game**

### Demo video

👉 **[NEW DEMO VIDEO LINK — INSERT HERE]**

---

## 💡 Why this project matters

Fruit Tank Academy demonstrates how several disciplines can fit together in one deployable learning product:

**Game mechanics + English learning + adaptive review + cloud architecture + security-aware data design**

The project started as a spelling-game experiment and has evolved into a portfolio-ready EdTech product prototype with persistent learner state, a structured learning data model, a review loop, and a clear production boundary.

---

## 👤 Creator

**Allen Yeung**  
Education · Digital Technology · AI & Cloud Learning

Building practical, technology-enhanced learning experiences that connect interaction design with measurable educational outcomes.

---

## 📌 Project status

**Active EdTech product prototype / portfolio project**

Core gameplay, authentication, cloud progress synchronization, and adaptive review are implemented and deployed. Future work can expand the vocabulary library, classroom tooling, analytics, teacher workflows, and more advanced server-authoritative review logic.

---

## 📄 License

No license file is currently included. All rights reserved unless otherwise stated by the repository owner.

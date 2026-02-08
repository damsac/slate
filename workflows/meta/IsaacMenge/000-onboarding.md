---
id: "000"
title: "Onboarding: IsaacMenge"
status: active
author: IsaacMenge
project: Slate
tags: [onboarding, brainstorming, ideation]
sessions:
  - id: 3141a818
    slug: app-brainstorming-and-ideation
    dir: home
prompts: []
created: "2026-02-04T02:16:00Z"
updated: "2026-02-08T01:27:00Z"
---

# 000: Onboarding — IsaacMenge

## Context

Before joining the Slate project as a collaborator, spent several days brainstorming app ideas with Claude in a home directory session. The conversation started broad (general app concepts) and progressively narrowed toward a todo/task management app focused on mental offloading — the same concept gudnuf was independently researching and building.

## Timeline

### Phase 1: Initial Brainstorming (`3141a818`, Feb 4)

**What**: Open-ended exploration of app ideas with Claude. Started from "help me brainstorm some app ideas" with no specific direction.

**Developer thinking**: Goals were to learn iOS development and build something with revenue potential. Discussed what apps are used daily — social media, Safari, messages, budget tracking — to identify gaps in personal workflow.

### Phase 2: Narrowing the Concept (Feb 7-8)

**What**: Returned to the brainstorming session days later with a clearer direction. Conversation evolved toward task management and mental offloading.

**Key moments**:
- Gravitated toward the "offload" concept — an app for dumping tasks out of your head
- Liked the "brain dump" direction — quick capture without friction
- Discussed "today or later" sorting as a core interaction pattern
- Resonated with the idea that the value isn't productivity — it's peace of mind

**Connection to Slate**: These ideas aligned directly with what gudnuf was building independently. The "brain dump" and "today vs later" concepts map to Slate's Today/Backlog architecture and its "mental offloading tool" philosophy described in [gudnuf/000-research-and-ideation.md](../gudnuf/000-research-and-ideation.md).

## First Impressions of the Project

After joining the Slate repo and reading through gudnuf's meta entries:

- **The meta/prompt workflow is the interesting part**, not the todo app itself. The system for documenting decisions, tracking prompts, and creating an audit trail of thinking is genuinely novel.
- **Skills as human-readable, Claude-executable docs** is a clean abstraction. Reading `.claude/skills/prompt/SKILL.md` makes sense both as documentation and as AI instructions.
- **The research-first approach** (2 hours before any code) produced a spec that built the entire app in one session. That's a strong signal for the workflow.

## Questions / Confusion Points

- The PR description references steps (1-6) but skips Step 5 — minor but noticeable
- `/setup` skill wasn't discovered automatically by Claude Code on first session — required understanding that skills load at session startup
- The relationship between meta entries and prompt files wasn't immediately clear until reading both gudnuf entries

## What I'd Do Differently

- The onboarding doc should mention that `direnv allow` is needed before tools work, and that a fresh terminal/Claude session is required after
- Bundle ID conflicts on device deployment should be called out earlier — it's a blocker that requires code changes
- The template file (`000-template.md`) is helpful but could include a quick-start checklist instead of just section headers

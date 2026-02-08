---
name: prompt
description: Prompt engineering workflow. Use when the user says "/prompt", "make a prompt", "prompt", or wants to turn an idea into a well-structured prompt. Cleans up raw input, presents for review, then enters plan mode for execution.
---

# Prompt

Turn raw user input into a well-engineered prompt, review it, then plan and execute.

## Critical Rules

- **NEVER execute without explicit "Do it" from the user.** The review step is mandatory. Do not skip it.
- **NEVER repeat or summarize what you just did.** Keep the conversation flowing forward. The user saw your output — don't recap it. After completing a step, move to the next step or wait for input. No "Here's what was created" or "Done. Here's what I built" summaries.
- **Stay in flow.** Each message should either present new information or ask for a decision. Nothing else.

## Workflow

### 1. Clean & Structure

Take the user's raw input and return:
- **Goal**: One sentence at the top summarizing intent
- **Body**: Their ideas restructured for scannability. Reformatted, not rewritten. Do not add complexity or assumptions. This is their thinking, clarified.

Do not repeat the full prompt later in conversation — the user already read it. If they need to see it again, that's what "What did I say?" is for.

### 2. Review

Present via `AskUserQuestion` with two options:
- **Do it** — proceed to iteration and execution
- **What did I say?** — re-display the full cleaned-up prompt (user's ideas only, no Claude additions)

**Stop here and wait.** Do not proceed to step 3 until the user explicitly selects "Do it". Any other input means they want to revise — incorporate their feedback and re-present.

### 3. Iterate & Warn

Only after "Do it". Iterate on the prompt one more time using conversation context. This version is yours — add analysis the user didn't surface.

**Warn the user** if their suggestions indicate:
- Architectural changes that could destabilize the app
- Design hacks or workarounds
- Patterns that introduce unnecessary complexity

Surface warnings before executing so the user can reconsider.

### 4. Plan & Execute

Enter plan mode (`EnterPlanMode`) with the final iterated prompt. Explore the codebase, design the implementation, and present the plan for user approval before making changes.

Execute in the main conversation — no subagent.

### 5. Save Prompt File

Create `workflows/prompts/<unix-timestamp>.md`:

```markdown
---
status: executed
goal: "<one sentence>"
author: "<user>"
project: "<project name>"
tags: [<framework>, <domain>, <theme>]
conversation_id: "<claude code conversation id if available>"
commit_hash: "<filled at commit time>"
created: "<ISO 8601 timestamp>"
---

# <Goal as title>

## Human Prompt

<The cleaned-up prompt the human approved before hitting "do it">

## Plan

<The iterated prompt Claude built from the human's input — includes analysis, architecture considerations, and implementation approach>

## Autonomous Considerations

<Decisions Claude made without explicit human direction during planning/execution. What was inferred, assumed, or chosen independently. Reviewers should verify these align with intent.>

## Flagged Issues & Resolutions

<Issues Claude surfaced during iteration/planning and how the developer chose to handle them. Empty if none were flagged.>

## Result

<Filled at commit time: outcome, different approach taken, discarded, etc.>
```

### Prompt File Indexing

Frontmatter fields are the index. Searchable by:
- `author`, `project`, `tags`, `conversation_id`, `commit_hash`, `status`

Use `Grep` across `workflows/prompts/` frontmatter to query the library.

### Prompt Design Philosophy

When iterating on the agent prompt:
- Show architecture, models, and key components — not implementation code
- Build from first principles based on current app state
- Optimize for robustness and stability
- No unnecessary complexity
- Every change should strengthen the foundation

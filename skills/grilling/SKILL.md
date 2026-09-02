---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet.

## Running a round with AskUserQuestion

For each round, call `AskUserQuestion` to put the whole frontier to the user in one structured interaction:

- **1 question per open decision.** If the frontier has more than 4 open decisions, ask the 4 most decision-critical first, then continue in a follow-up call for the rest (AskUserQuestion caps at 4 questions per call).
- **Options = the plausible answers** for that decision (2–4 options each). Put your **recommended answer first** (the UI highlights it as the default), and describe why in the option's description.
- **multiSelect = true** only when a decision legitimately allows several simultaneous answers.
- The user can always type a freeform answer instead of picking an option — that's fine, treat it as their decision.

Example shape for a frontier with two open decisions:

```
AskUserQuestion:
  Q1 "Which database should we use?" →
    options: PostgreSQL ("Recommended: battle-tested, best ecosystem"),
             MySQL ("If you need it for existing infra"),
             SQLite ("If this is a small embedded app")
  Q2 "How should auth work?" →
    options: OAuth2 ("Recommended: industry standard"),
             API keys ("Simpler, for internal tools"),
             Session cookies ("Traditional web sessions")
```

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them via `AskUserQuestion` and wait.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding — confirm with a final `AskUserQuestion` (e.g. "Have we reached a shared understanding?" options `Yes, proceed` / `No, keep grilling`) rather than asking in prose.

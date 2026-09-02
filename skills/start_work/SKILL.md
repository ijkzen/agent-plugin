---
name: start_work
description: End-to-end feature development pipeline. Takes the user's natural-language request and drives it through requirement refinement (grill-with-docs + ponytail), spec generation (to-spec), ticket breakdown (to-tickets), implementation (implement + tdd), review (code-review + ponytail-review), fix, and a final commit prompt. Use when the user gives a feature/change request and wants the full workflow run, or says "start work", "build this feature", "implement this request", "take this from idea to done".
disable-model-invocation: false
version: 1.0.0
---

# Start Work

Drive a user request from raw idea → refined requirements → spec → tickets → implemented code → reviewed & fixed → ready to commit.

This is an **orchestrator**: it delegates each stage to a dedicated skill and carries the produced artifacts forward. Do not re-implement what a stage skill already does.

## Reference files

| File | Contents | Read in |
|---|---|---|
| `STAGE-REFERENCE.md` | per-stage boundaries, handoff artifacts, error handling, dependency-availability checks | every stage |

## Pipeline overview

```
User request
   │
   ▼  Stage 1  refine requirements (grill-with-docs + ponytail)
   ▼  Stage 2  write spec (to-spec)
   ▼  Stage 3  break into tickets (to-tickets)
   ▼  Stage 4  implement each ticket (implement + tdd)
   ▼  Stage 5  review (code-review + ponytail-review)
   ▼  Stage 6  fix review findings
   ▼  Stage 7  ask user whether to commit
```

## Gates before starting

1. **Skill availability** — before running, confirm each referenced skill is callable:
   - In-repo skills: `grill-with-docs`, `to-spec`, `to-tickets`, `implement`, `tdd`, `code-review` (all in this plugin's `skills/`).
   - External-plugin skills (require the `ponytail` marketplace dependency installed): `ponytail`, `ponytail-review`.
   - If any external skill is unavailable → tell the user it's missing, and `AskUserQuestion`: "Proceed without it?" `Yes, use fallback` (code-review only, no redundancy pass) / `No, install ponytail first`. See `STAGE-REFERENCE.md` → "Dependency availability".
2. **Git repo** — confirm `git rev-parse --is-inside-work-tree`. If not, abort with a message (this pipeline commits at the end).
3. **Capture the request** — record the user's exact words as the source of truth; everything downstream traces to it.

## Stage quick map (details: `STAGE-REFERENCE.md`)

1. **Refine** — invoke `grill-with-docs` to sharpen the request against docs, then `ponytail` to cut anything not strictly needed (YAGNI). Output: refined requirements.
2. **Spec** — invoke `to-spec` on the refined requirements. Output: spec artifact (per to-spec's own format/location).
3. **Tickets** — invoke `to-tickets` on the spec. Output: ticket list with dependencies.
4. **Implement** — for each ticket in dependency order: invoke `implement` + `tdd`; verify each ticket's tests go red→green before moving on. Output: working, tested code.
5. **Review** — invoke `code-review` (correctness) and `ponytail-review` (over-engineering) on the full diff. Output: two finding lists.
6. **Fix** — address findings: critical first, then suggestions (ask before acting on nitpicks). Re-run affected tests. Output: repaired code.
7. **Commit gate** — `AskUserQuestion`: "Commit this work?" `Yes, commit` / `No, leave changes`. On Yes, write a conventional-commit message; on No, leave working tree as-is and summarize.

## Hard rules

- **Pipeline integrity** — do not skip stages or merge them silently; each stage gates the next.
- **No fabrication** — every stage reports real artifacts (real spec file, real tickets, real test output, real review findings).
- **Stop on user veto** — the user can halt at any stage; stop cleanly, summarize progress, and do not auto-continue.
- **External dependencies** — never assume `ponytail`/`ponytail-review` are present; check and ask (gate above).
- **Commit is user-gated** — never commit without the Stage 7 explicit Yes.

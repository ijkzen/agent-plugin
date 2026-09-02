---
name: setup
description: One-shot project setup that runs setup-matt-pocock-skills, then quality_engineering_assurance, then installs and initializes codegraph (adding .codegraph to .gitignore). Use when the user asks to set up a project/repo for the first time, "setup this project", or "run the full setup".
disable-model-invocation: false
version: 1.0.0
---

# Setup

Run the project's full first-time setup in **three ordered phases**. Each phase is a gate: if a phase fails or the user declines an install, stop that phase and report — never silently continue into a phase whose prerequisite failed.

## Reference files

| File | Contents | Read in |
|---|---|---|
| `CODEGRAPH-REFERENCE.md` | codegraph existence check, platform-aware install, init, `.gitignore` handling, PATH retry | Phase 3 |

## Phase 1 — Run `setup-matt-pocock-skills`

1. Check the `setup-matt-pocock-skills` skill is available (this plugin's `skills/`, or the agent's available skills).
   - **Available** → invoke via the Skill tool and follow it to completion.
   - **Not available** → report: "setup-matt-pocock-skills is not installed." `AskUserQuestion`: "Continue to Phase 2 without it?" → `Yes, continue` / `No, abort`. Only continue on explicit Yes.
2. Let `setup-matt-pocock-skills` ask its own questions (issue tracker, triage labels, domain layout) — do not pre-answer or skip them.
3. After it finishes, verify its outputs exist (e.g. `docs/agents/issue-tracker.md`). If it was skipped, note that in the final report.

## Phase 2 — Run `quality_engineering_assurance`

1. Check the `quality_engineering_assurance` skill is available.
   - **Available** → invoke via the Skill tool and follow it to completion (it handles per-language tool config, verification, pre-commit hooks, CI workflow, AGENTS.md CI notes — each gated on user approval).
   - **Not available** → report, then `AskUserQuestion` whether to continue to Phase 3.
2. Do not skip its per-tool questions for speed — granularity is intentional. If the user aborts mid-phase, stop cleanly, summarize what completed, and do not proceed to Phase 3 unless asked.

## Phase 3 — Install & initialize `codegraph`

Follow `CODEGRAPH-REFERENCE.md` exactly: check exists → if missing, `AskUserQuestion` before installing → platform-aware install (npm if Node present, else official script) → re-check PATH → `codegraph init` (only if confirmed present) → append `.codegraph/` to `.gitignore` (never overwrite; ask before creating one).

**Gate rules (from the reference):**
- User declines install → skip this phase entirely: no `init`, no `.gitignore` edit.
- Install fails after retry → mark codegraph skipped, report, do not run init.
- Not a git repository → stop Phase 3 (`init` + `.gitignore` need a repo); Phases 1–2 still reported as applicable.

## Final report

| Phase | Result |
|---|---|
| setup-matt-pocock-skills | ✅ completed / ⚠️ skipped (reason) / ❌ failed (reason) |
| quality_engineering_assurance | ✅ completed / ⚠️ skipped / ❌ failed + per-tool state summary |
| codegraph | ✅ installed + init'd + ignored / ⚠️ skipped (user declined or unavailable) / ❌ failed (reason) |

List every skipped item with its reason and the exact command the user can run later to finish it.

## Hard rules

- **Never install anything without an explicit Yes** via `AskUserQuestion`.
- User declines an install → skip that item, **do not continue to its dependent next step** (no init if no install; no gitignore edit if no init).
- Never overwrite `.gitignore` or any existing file; append or ask.
- Never fabricate a codegraph init success — verify `.codegraph/` exists before claiming it.

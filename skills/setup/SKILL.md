---
name: setup
description: One-shot project setup that runs setup-matt-pocock-skills, then quality_engineering_assurance, then installs and initializes codegraph (adding .codegraph to .gitignore). Use when the user asks to set up a project/repo for the first time, "setup this project", or "run the full setup".
disable-model-invocation: false
version: 1.0.0
---

# Setup

Run the project's full first-time setup in **three ordered phases**. Each phase is a gate: if a phase fails or the user declines an install, stop that phase and report — never silently continue into a phase whose prerequisite failed.

## Phase 1 — Run `setup-matt-pocock-skills`

1. Check the `setup-matt-pocock-skills` skill is available (in this plugin's `skills/`, or in the agent's available skills).
   - **Available** → invoke it via the Skill tool and follow it through to completion.
   - **Not available** → do NOT guess. Report: "setup-matt-pocock-skills is not installed; run it from the agent-plugin marketplace or skip this phase." `AskUserQuestion`: "Continue to Phase 2 without it?" options `Yes, continue` / `No, abort`. Only continue on explicit Yes.

2. **Boundary:** `setup-matt-pocock-skills` itself may ask the user questions (issue tracker, triage labels, domain layout). Let it do its own asking — do not pre-answer or skip its questions.

3. After it finishes, verify its outputs exist as expected (e.g. `docs/agents/issue-tracker.md`). If it produced nothing because it was skipped, note that in the final report.

## Phase 2 — Run `quality_engineering_assurance`

1. Check the `quality_engineering_assurance` skill is available.
   - **Available** → invoke it via the Skill tool and follow it through to completion (it handles per-language tool config, verification, pre-commit hooks, CI workflow, and AGENTS.md CI-tracking notes, each gated on user approval).
   - **Not available** → same as Phase 1: report, then `AskUserQuestion` whether to continue to Phase 3.

2. **Boundary:** this phase may take a long time (per-tool installs, per-tool hook questions). Do not skip its per-tool questions for speed — the granularity is intentional. If the user wants to abort mid-phase, stop cleanly, summarize what was completed, and do not proceed to Phase 3 unless asked.

## Phase 3 — Install & initialize `codegraph`

This phase requires the `codegraph` CLI (the `colbymchenry/codegraph` project — pre-indexed code knowledge graph; `codegraph init` creates `.codegraph/` and builds the graph).

### 3.1 Check if `codegraph` exists

```bash
command -v codegraph
```

- **Exists** → go straight to **3.3 Initialize** (no install, no question).
- **Does not exist** → proceed to **3.2 Install** (which itself asks first).

### 3.2 Install `codegraph` (only after user approval)

1. **Ask first.** `AskUserQuestion`: "`codegraph` is not installed. Install it?" options `Yes, install codegraph` / `No, skip codegraph`. 
   - **No** → skip this phase entirely. Do NOT run `codegraph init`, do NOT touch `.gitignore` for codegraph. Report that codegraph was skipped by user choice. **Stop here for this phase** — do not continue to init.
2. On **Yes**, detect the platform and available tooling, in this preference order:
   - **Node.js present** (`command -v node`) → `npm i -g @colbymchenry/codegraph` (works on any OS, recommended).
   - **No Node, macOS/Linux** → official script installer: `curl -fsSL <https://codegraph-get.colbymchenry.com/> | sh` (no Node required). **Boundary:** this pipes a remote script to a shell — only run it because the user already approved installation; if the fetch fails or the script errors, stop and report the exact error; do not fall back to a different unofficial installer without asking.
   - **No Node, Windows** → PowerShell: `irm <https://codegraph-get.colbymchenry.com/> | iex`. If neither Node nor the script route works, report and mark codegraph skipped.
3. After install, re-check `command -v codegraph`. **Boundary:** the installer may add `codegraph` to PATH for *new* shells only. If `command -v` still fails in the current shell, try `export PATH="$PATH:$(npm bin -g 2>/dev/null)"` or re-source the shell profile; only if it still cannot be found do you report it as failed.
4. Installation failed or user declined → mark codegraph skipped, do not proceed to init.

### 3.3 Initialize in the current project

Only run this if `codegraph` is now confirmed present:

```bash
codegraph init
```

- **Success** → a `.codegraph/` directory was created (and the graph built).
- **Failure** → stop. Report the error. If it failed because a stale lock file exists, try `codegraph clear` per the tool's docs; otherwise do not force it.

### 3.4 Add `.codegraph/` to `.gitignore`

1. Check a `.gitignore` exists at the repo root.
   - **Exists** → check whether `.codegraph/` (or a broader rule matching it, e.g. `.codegraph*`) is already listed. If already covered → nothing to do, confirm to user. If not → append the line.
   - **Does not exist** → `AskUserQuestion`: "No `.gitignore` exists — create one?" options `Yes, create with .codegraph/` / `No, skip`. On Yes, create a minimal `.gitignore` containing `.codegraph/` (only add other entries if the user asks). On No, note that `.codegraph/` was left unignored.
2. **Boundary:** do not overwrite an existing `.gitignore`; always append. Keep the append minimal (one line) unless the file already has structure.

## Final report

Summarize all three phases:

| Phase | Result |
|---|---|
| setup-matt-pocock-skills | ✅ completed / ⚠️ skipped (reason) / ❌ failed (reason) |
| quality_engineering_assurance | ✅ completed / ⚠️ skipped / ❌ failed + summary of per-tool state |
| codegraph | ✅ installed + init'd + ignored / ⚠️ skipped (user declined or unavailable) / ❌ failed (reason) |

List every skipped item with its reason and the exact command the user can run later to finish it.

## Hard rules

- **Never install anything without an explicit Yes** via `AskUserQuestion`.
- User declines an install → skip that item, **do not continue to the dependent next step** (e.g. no init if no install; no gitignore edit if no init).
- Never overwrite `.gitignore` or any existing file; append or ask.
- Never fabricate a codegraph init success — verify `.codegraph/` exists before claiming it.
- If the repo is not a git repository, stop Phase 3 (codegraph init + gitignore need a repo); still report Phases 1–2 as applicable.

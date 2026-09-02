---
name: quality_engineering_assurance
description: Configure, verify, and wire up code-quality gates (linters + unit/integration test frameworks) for every language in a project, then optionally add git pre-commit hooks, CI workflows for the hosting platform (GitHub/GitLab/Gitea), and CI-status tracking notes in AGENTS.md. Use when the user asks to set up code quality checking, test tooling, quality gates, pre-commit hooks, or CI workflows for a repository.
disable-model-invocation: false
version: 1.0.0
---

# Quality Engineering Assurance

Configure quality gates for **every language detected in the current repository**, verify they work, and wire them into hooks and CI.

## Reference files (read when the step needs them)

| File | Contents | Read in |
|---|---|---|
| `LANGUAGE-TOOL-MATRIX.md` | 12-language detection signals + canonical tool/framework selection | Step 0 & 1 |
| `INSTALL-REFERENCE.md` | existence checks, platform-aware install commands, failure handling | Step 1 |
| `VERIFY-REFERENCE.md` | per-tool run commands + smoke-test method + build prerequisites | Step 2 |
| `HOOKS-AND-CI.md` | pre-commit script shape, hook test/revert, CI file locations, CI-tracking commands | Steps 3–6 |

> The canonical tool selection in `LANGUAGE-TOOL-MATRIX.md` comes from the project's engineering docs. **Never swap in a different tool for a listed language without asking the user.**

## Workflow

### Step 0 — Inventory the repository

1. Confirm git repo: `git rev-parse --is-inside-work-tree`. If not, `AskUserQuestion`: "This doesn't look like a git repository. Proceed anyway?" → `Yes, proceed here` / `No, abort`. Abort ends the skill.
2. Detect languages per `LANGUAGE-TOOL-MATRIX.md` (read root files only; skip `node_modules`, `vendor`, `.git`, build dirs).
3. No languages detected → `AskUserQuestion`: "No languages detected — which languages should I configure?" (freeform). If none named, end with a summary.

### Step 1 — Configure tooling per language

For each detected language: check the tool binary exists → if missing, **ask before installing** → platform-aware install per `INSTALL-REFERENCE.md` → offer minimal config only if the standard config file is missing (never overwrite existing). Test frameworks that ship with the language (Go/Rust/Swift/C#/Java) need no install ask. Full details: `INSTALL-REFERENCE.md`.

### Step 2 — Verify each tool works

Run each quality tool and test framework per `VERIFY-REFERENCE.md` (canonical commands, build prerequisites, throwaway smoke test if the repo has zero tests — then delete it). Record per tool: `✅ working` / `❌ skipped (reason)` / `⚠️ verification failed (reason)`.

### Step 3 — Offer pre-commit hooks (per tool, fine-grained)

Ask **once per tool** (quality tool and test framework, for each language): `AskUserQuestion` "Add `<T>` to the pre-commit hook?" `Yes` / `No`. Recommended Yes for quality tools; surface the "tests in pre-commit can be slow" trade-off for frameworks. Collect Yes answers into a plain `.git/hooks/pre-commit` shell script (or a `pre-commit` framework entry if the repo already uses it). Script shape + backup rule: `HOOKS-AND-CI.md`.

### Step 4 — Test the hook, then revert

Stage a no-op edit, attempt `git commit`. Hook passes → `git reset --soft HEAD~1` to revert, confirm to user. Hook fails → report (correctly blocked), then `AskUserQuestion`: fix-and-retry vs relax. Never silently bypass. Details: `HOOKS-AND-CI.md`.

### Step 5 — CI workflow for the hosting platform

Ask hosting platform (`GitHub` / `GitLab` / `Gitea` / `None`), ask whether to add a CI workflow, then create it at the canonical location (GitHub → `.github/workflows/ci.yml`; GitLab → `.gitlab-ci.yml`; **Gitea → `.gitea/workflows/ci.yml`**). Workflow content = per-language jobs running the `VERIFY-REFERENCE.md` commands; use only widely-available setup actions. Gitea offline-from-GitHub caveat and never-overwrite rule: `HOOKS-AND-CI.md`.

### Step 6 — CI-status tracking in AGENTS.md

Ask whether future agents should track CI after pushes. If yes, append a `## CI tracking` section to `AGENTS.md` (or `CLAUDE.md`; if neither exists ask which to create) with the platform + watch command (`gh run watch` / `glab ci status` / `tea actions`). If the tracking CLI is missing, ask before installing. Details: `HOOKS-AND-CI.md`.

## Final report

Compact table per language: quality tool / test framework / hooks added / CI workflow / notes, then every skipped item with its reason and the exact command to finish it later.

## Hard rules

- **Never install anything without an explicit Yes** via `AskUserQuestion`. No → skip that item, continue, don't nag.
- **Never fake a successful verification** — show the error.
- **Never overwrite** an existing config file, CI file, or hook without backing up / asking.
- **Never leave throwaway files** (smoke tests, hook-test commits) in the repo.
- One question per tool, per language — granularity is a feature.

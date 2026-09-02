# codegraph setup reference — install, init, gitignore

`codegraph` = the `colbymchenry/codegraph` project: a pre-indexed code knowledge graph for AI agents. `codegraph init` creates `.codegraph/` in the project and builds the graph in one step. Fully local.

## 1. Existence check

```bash
command -v codegraph
```

- Present → skip install, go straight to **Initialize**.
- Missing → **ask first**, never install silently:
  `AskUserQuestion` "`codegraph` is not installed. Install it?" → `Yes, install codegraph` / `No, skip codegraph`.
- **No** → skip the whole codegraph phase. Do NOT run `init`, do NOT touch `.gitignore` for codegraph.

## 2. Platform-aware install (only after explicit Yes)

Preference order:

1. **Node.js present** (`command -v node`) → `npm i -g @colbymchenry/codegraph` (works on any OS — preferred).
2. **No Node, macOS/Linux** → official script installer (no Node required):
   `curl -fsSL https://codegraph-get.colbymchenry.com/ | sh`
   ⚠️ This pipes a remote script into a shell — acceptable only because the user already approved installation. If fetch/execution errors, stop and report the exact error. Do NOT substitute an unofficial installer without asking.
3. **No Node, Windows** → PowerShell: `irm https://codegraph-get.colbymchenry.com/ | iex`

## 3. Post-install re-check (PATH boundary)

The installer adds `codegraph` to PATH for **new shells only**. If `command -v codegraph` still fails in the current shell:

```bash
export PATH="$PATH:$(npm bin -g 2>/dev/null)"
# or re-source the shell profile: source ~/.bashrc (Linux) / ~/.zshrc (macOS)
```

Only report as failed after this one retry. Install failed or user declined → mark skipped, do NOT run init.

## 4. Initialize (only if codegraph is confirmed present)

```bash
codegraph init
```

- Success → `.codegraph/` created + graph built.
- Failure → stop, report the error. If a stale lock file blocks indexing, try `codegraph clear` per the tool's docs. Do not force it.

## 5. Add `.codegraph/` to `.gitignore`

1. `.gitignore` exists?
   - Yes → check `.codegraph/` (or a broader rule like `.codegraph*`) is already listed. Covered → nothing to do. Not covered → **append** the line.
   - No → `AskUserQuestion`: "No `.gitignore` exists — create one?" → `Yes, create with .codegraph/` / `No, skip`. On Yes create a minimal `.gitignore` with `.codegraph/`; on No note it was left unignored.
2. Never overwrite an existing `.gitignore` — append only.

## Failure summary

codegraph phase result is one of:
- ✅ installed + init'd + ignored
- ⚠️ skipped (user declined / tool unavailable after retry)
- ❌ failed (reason)

List the exact command the user can run later to finish: `npm i -g @colbymchenry/codegraph && codegraph init && echo '.codegraph/' >> .gitignore`.

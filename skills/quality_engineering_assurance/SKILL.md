---
name: quality_engineering_assurance
description: Configure, verify, and wire up code-quality gates (linters + unit/integration test frameworks) for every language in a project, then optionally add git pre-commit hooks, CI workflows for the hosting platform (GitHub/GitLab/Gitea), and CI-status tracking notes in AGENTS.md. Use when the user asks to set up code quality checking, test tooling, quality gates, pre-commit hooks, or CI workflows for a repository.
disable-model-invocation: false
version: 1.0.0
---

# Quality Engineering Assurance

Configure quality gates for **every language detected in the current repository**, verify they work, and wire them into hooks and CI.

The canonical per-language tool selection below comes from the project's own engineering docs (12 languages, one linter + one test framework each). **Never swap in a different tool for a listed language without asking the user.**

## Language & tool reference (canonical)

| Language | Detected by (repo signals) | Quality tool | Test framework |
|---|---|---|---|
| Python | `pyproject.toml`, `requirements*.txt`, `setup.py`, `Pipfile`, `*.py` | Ruff | pytest |
| JavaScript/TypeScript | `package.json`, `*.ts`, `*.tsx`, `*.js`, `*.jsx` | Biome | Vitest |
| Java | `pom.xml`, `build.gradle(.kts)`, `src/main/java` | PMD | JUnit 5 |
| C | `CMakeLists.txt`, `Makefile`, `*.c`, `*.h` | cppcheck | Check |
| C++ | `CMakeLists.txt`, `*.cpp`, `*.hpp`, `*.cc`, `*.h` | clang-tidy | GoogleTest |
| C# | `*.sln`, `*.csproj`, `*.cs` | .NET Analyzers | xUnit |
| Go | `go.mod`, `*.go` | golangci-lint | go test |
| Rust | `Cargo.toml`, `*.rs` | clippy | cargo test |
| PHP | `composer.json`, `*.php` | PHPStan | PHPUnit |
| Ruby | `Gemfile`, `*.rb` | RuboCop | RSpec |
| Swift | `Package.swift`, `*.swift`, `*.xcodeproj` | SwiftLint | XCTest |
| Kotlin | `build.gradle.kts` with kotlin plugin, `*.kt` | detekt | JUnit 5 |

> **Boundary:** a language counts as "present" when at least one repo signal exists **or** the user confirms they work in it. Do not assume a language from a stray file (e.g. one `*.js` in a Python repo) — if signals conflict, call `AskUserQuestion` to confirm which languages are actually in scope.

## Workflow

### Step 0 — Inventory the repository

1. Check you are in a git repository root (`git rev-parse --is-inside-work-tree`). If not, `AskUserQuestion`: "This doesn't look like a git repository. Proceed anyway?" options `Yes, proceed here` / `No, abort`. Abort ends the skill.
2. Detect languages from the table above (read root files, do not recurse into `node_modules`, `vendor`, `.git`, build dirs).
3. Present the detected language list. If none detected, `AskUserQuestion`: "No languages detected — which languages should I configure?" with freeform answer expected; if the user names none, end the skill with a summary.

### Step 1 — Configure quality + test tooling for each language

For each detected language, in this order:

1. **Check the tool binary** exists (per-language check commands below). If present → use it directly. If missing → **do not install silently**: call `AskUserQuestion` "Install `<tool>`?" options `Yes, install it` (proceed to platform-aware install), `No, skip it` (mark language's quality tool as skipped and continue with its test framework). If the user declines, skip **only that tool**, not the whole language.
2. **Platform-aware install** (only after user approval), in preference order per OS:
   - **macOS**: `brew install <formula>` first if Homebrew exists; fall back to the language-native installer.
   - **Linux (Debian/Ubuntu)**: `apt-get install -y <pkg>` if the package exists (check with `apt-cache policy` first); otherwise language-native installer.
   - **Any OS**: language-native installer as the portable fallback (table below).
   - After install, re-run the existence check. If it still fails, report the error and mark that tool skipped — **never fake success**.
3. **Config files**: if the tool is installed but its standard config file is missing, offer to create a minimal one (`AskUserQuestion`, `Yes, write minimal config` / `No, use defaults`). Never overwrite an existing config file.
4. **Test framework**: same existence-check → ask → install pattern. Note some frameworks ship with the language (Go `go test`, Rust `cargo test`, Swift `XCTest`) — treat as always-present, no install question needed.

**Binary existence checks & installers (canonical):**

| Language | Quality tool check | Quality tool install (native) | Test check | Test install (native) |
|---|---|---|---|---|
| Python | `command -v ruff` | `pip install ruff` (or `uv tool install ruff`) | `python -m pytest --version` | `pip install pytest pytest-cov` |
| JS/TS | `test -x node_modules/.bin/biome` | `npm i -D @biomejs/biome` | `test -x node_modules/.bin/vitest` | `npm i -D vitest` |
| Java | `command -v mvn \|\| command -v gradle` (plugins resolve from build file) | n/a (build tool) | same as quality | n/a |
| C | `command -v cppcheck` | `apt-get install -y cppcheck` / `brew install cppcheck` | `command -v pkg-config && pkg-config --modversion check` | `apt-get install -y check` / `brew install check` |
| C++ | `command -v clang-tidy` | `apt-get install -y clang-tidy` / `brew install llvm` | via CMake FetchContent (no binary) | n/a |
| C# | `command -v dotnet` (analyzers built-in) | n/a | `command -v dotnet` | n/a |
| Go | `command -v golangci-lint` | `curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \| sh -s -- -b $(go env GOPATH)/bin` | `command -v go` | n/a |
| Rust | `cargo clippy --version` | `rustup component add clippy` | `command -v cargo` | n/a |
| PHP | `test -x vendor/bin/phpstan` | `composer require --dev phpstan/phpstan` | `test -x vendor/bin/phpunit` | `composer require --dev phpunit/phpunit` |
| Ruby | `bundle exec rubocop --version` | `gem install rubocop` (add to Gemfile) | `bundle exec rspec --version` | `gem install rspec` (add to Gemfile) |
| Swift | `command -v swiftlint` | `brew install swiftlint` | `command -v swift` | n/a |
| Kotlin | `./gradlew detekt` resolves plugin | add `id("io.gitlab.arturbosch.detekt")` to build | `./gradlew test` | n/a |

> **Boundary:** if the platform's package manager is unavailable and the native installer needs network that fails, stop that tool, report exactly what failed and what command was attempted. Move on to the next tool. Collect all failures for the final report.

### Step 2 — Verify each tool actually works

After configuration, run the tool against the project and confirm **it works**, using a light smoke test per the project's own verification docs pattern:

1. **Quality tool**: run its check command on the real codebase (table below). Expected: it either passes (exit 0) or reports real findings (exit != 0 with output) — **both prove it runs**. Only "command not found" / crash / no output at all is a failure.
2. **Test framework**: run the test command. If there are zero tests in the repo, create **one throwaway smoke test** in the framework's convention (e.g. `tests/test_smoke.py` asserting `1+1==2`), run it, confirm it passes, then **delete the throwaway file** (do not leave it in the repo).
3. Record per-tool: `✅ working` / `❌ skipped (reason)` / `⚠️ configured but verification failed (reason)`.

**Canonical run commands:**

| Language | Quality run | Test run |
|---|---|---|
| Python | `ruff check . && ruff format --check .` | `pytest -q` |
| JS/TS | `npx biome ci .` | `npx vitest run` |
| Java | `mvn pmd:check` (or `gradle pmdMain`) | `mvn test` (or `gradle test`) |
| C | `cppcheck --enable=all --error-exitcode=1 src/` | `ctest --test-dir build --output-on-failure` (build first) |
| C++ | `clang-tidy src -p build/ --checks='bugprone-*,performance-*'` | `ctest --test-dir build --output-on-failure` |
| C# | `dotnet build -warnaserror` | `dotnet test` |
| Go | `golangci-lint run ./...` | `go test ./...` |
| Rust | `cargo clippy --all-targets --all-features -- -D warnings` | `cargo test` |
| PHP | `vendor/bin/phpstan analyse src --level=8 --no-progress` | `vendor/bin/phpunit` |
| Ruby | `bundle exec rubocop` | `bundle exec rspec` |
| Swift | `swiftlint lint --strict` | `swift test` |
| Kotlin | `./gradlew detekt` | `./gradlew test` |

> **Boundary:** if a project requires building first (C/C++ CMake, C# restore), do that before verifying and note it. If the build itself fails for reasons unrelated to tooling, report it as "build prerequisite failed" rather than a tool failure.

### Step 3 — Offer pre-commit hooks (per tool, fine-grained)

Ask **once per tool** (quality tool and test framework, for each language) whether it should run in a pre-commit hook. The user said granularity matters — every tool gets its own question:

For each verified tool T: `AskUserQuestion`: "Add `<T>` to the pre-commit hook?" options `Yes` / `No` (recommended: Yes for quality tools, ask independently for test frameworks — tests in pre-commit can be slow; surface that trade-off in the question's description).

1. Collect the "Yes" answers into an ordered hook script.
2. **Hook mechanism**: prefer a plain `.git/hooks/pre-commit` shell script (zero extra dependency, works everywhere). Only if the repo already uses `pre-commit` framework (a `.pre-commit-config.yaml` exists) do you add an entry to it instead.
3. The script must `cd` to the repo root, run each selected tool in order, and `exit 1` on the first failure with a clear message. **Never** write a hook that bypasses failures (no `|| true`).
4. Existing `.git/hooks/pre-commit`? Back it up to `.git/hooks/pre-commit.bak-<timestamp>` before overwriting, and tell the user. If the repo is a worktree/shared hook setup (core.hooksPath set), respect that path.

### Step 4 — Test the hook, then revert

1. Stage a harmless real change or create a temporary file (`git add` a no-op edit, e.g. a comment line in an existing file — do not commit new junk files).
2. Attempt `git commit`. Expected outcomes:
   - **Hook passes** → commit succeeds → immediately **undo it**: `git reset --soft HEAD~1` (keeps the change staged), then unstage if desired. Confirm to the user the hook fired and was reverted.
   - **Hook fails** (a tool correctly rejects the change) → the commit is blocked. This is *correct behaviour*; report it. Then decide: fix the violation (preferred) or ask the user whether to keep the hook strict (`AskUserQuestion`: `Fix the violation and retry` / `Relax the hook for now`). Do not silently bypass.
3. Restore the repo to its pre-test state (the staged no-op edit can remain staged or be discarded — ask nothing, just leave the working tree clean and mention it).

### Step 5 — CI workflow for the hosting platform

1. `AskUserQuestion`: "Where is this repository hosted?" options `GitHub` / `GitLab` / `Gitea` / `None/not hosted`. 
2. `AskUserQuestion`: "Add a CI workflow that runs the quality checks and tests?" options `Yes, add it` / `No, skip`.
3. If yes, create the workflow file **in the platform's expected location** (this is the canonical answer):
   - **GitHub** → `.github/workflows/ci.yml`
   - **GitLab** → `.gitlab-ci.yml` (repo root)
   - **Gitea** → `.gitea/workflows/ci.yml` (Gitea does **not** read `.github/workflows/` by default)
   - **None** → skip with a note that no workflow was written.
4. Workflow content: one job per language group, running the same canonical commands from Step 2 on `ubuntu-latest` (or `macos-latest` for Swift). Use only widely-available setup actions (`actions/checkout@v4`, `actions/setup-python@v5`, `actions/setup-node@v4`, `actions/setup-java@v4`, `actions/setup-go@v5`, `ruby/setup-ruby@v1`, `dtolnay/rust-toolchain@stable`, `shivammathur/setup-php@v2`). For Gitea, note that `uses:` actions are downloaded from GitHub by default; if the instance is offline from GitHub, the user must mirror actions or the workflow will fail — surface this caveat in the final report.
5. Do **not** overwrite an existing CI file — if one exists, show the user and ask whether to replace/merge.

### Step 6 — CI-status tracking in AGENTS.md

1. `AskUserQuestion`: "After pushes, should future agents track CI status?" options `Yes, document it` / `No`.
2. If yes, find `AGENTS.md` (repo root; if absent, `CLAUDE.md`; if neither exists, ask which to create via `AskUserQuestion` — do not pick for them). Append or update a `## CI tracking` section recording:
   - The hosting platform (from Step 5).
   - The command future agents should use to watch CI after a push, per platform:
     - **GitHub**: `gh run watch` (interactive) or `gh run list --limit 5` / `gh run view <run-id>`. Requires `gh` authenticated.
     - **GitLab**: `glab ci status` / `glab ci view`. Requires `glab` authenticated.
     - **Gitea**: `tea` CLI (`tea actions`) or check via web UI; note `gh` does **not** work against Gitea.
   - A one-line rule: "after every push, run the platform command above and report the outcome; do not assume success."
3. If the tracking CLI (`gh`/`glab`/`tea`) is not installed, do **not** install it silently — `AskUserQuestion` whether to install, and if declined, still document the command with a note "CLI not installed".

## Final report

End with a compact summary table:

| Language | Quality tool | Test framework | Hooks added | CI workflow | Notes |
|---|---|---|---|---|---|
| ... | ✅/❌+reason | ✅/❌+reason | tool list or none | file path or none | caveats |

Then list anything skipped with its reason and the exact command the user can run later to finish that item.

## Hard rules

- **Never install anything without asking first** (`AskUserQuestion`, explicit Yes). User says No → skip that item and continue; do not retry, do not nag.
- **Never fake a successful verification.** If a tool errors, show the error.
- **Never overwrite** an existing config file, CI file, or hook without backing up / asking.
- **Never leave throwaway files** (smoke tests, hook-test commits) in the repo.
- One question per tool, per language — granularity is a feature, not a bug.

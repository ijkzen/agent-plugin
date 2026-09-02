# Install reference — existence checks & platform-aware installs

Use this when configuring a tool for a detected language. Flow per tool:

```
check exists ──► present? ──► use it directly (no question)
   │
   └─► missing? ──► AskUserQuestion "Install <tool>?" ──► No → skip this tool only
                                          └─► Yes → platform-aware install below
                                                     └─► re-check; still missing → report, skip
```

## Binary existence checks & native installers

| Language | Quality tool check | Quality tool install (native) | Test check | Test install (native) |
|---|---|---|---|---|
| Python | `command -v ruff` | `pip install ruff` (or `uv tool install ruff`) | `python -m pytest --version` | `pip install pytest pytest-cov` |
| JS/TS | `test -x node_modules/.bin/biome` | `npm i -D @biomejs/biome` | `test -x node_modules/.bin/vitest` | `npm i -D vitest` |
| Java | `command -v mvn \|\| command -v gradle` | n/a (plugin resolves via build tool) | same as quality | n/a |
| C | `command -v cppcheck` | `apt-get install -y cppcheck` / `brew install cppcheck` | `pkg-config --modversion check` | `apt-get install -y check` / `brew install check` |
| C++ | `command -v clang-tidy` | `apt-get install -y clang-tidy` / `brew install llvm` | via CMake FetchContent (no binary) | n/a |
| C# | `command -v dotnet` | n/a | `command -v dotnet` | n/a |
| Go | `command -v golangci-lint` | `curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh \| sh -s -- -b $(go env GOPATH)/bin` | `command -v go` | n/a |
| Rust | `cargo clippy --version` | `rustup component add clippy` | `command -v cargo` | n/a |
| PHP | `test -x vendor/bin/phpstan` | `composer require --dev phpstan/phpstan` | `test -x vendor/bin/phpunit` | `composer require --dev phpunit/phpunit` |
| Ruby | `bundle exec rubocop --version` | `gem install rubocop` (add to Gemfile) | `bundle exec rspec --version` | `gem install rspec` (add to Gemfile) |
| Swift | `command -v swiftlint` | `brew install swiftlint` | `command -v swift` | n/a |
| Kotlin | `./gradlew detekt` resolves plugin | add `id("io.gitlab.arturbosch.detekt")` to build | `./gradlew test` | n/a |

## Platform preference order (only after user approves install)

1. **macOS**: `brew install <formula>` first if Homebrew exists (`command -v brew`); fall back to the language-native installer.
2. **Linux Debian/Ubuntu**: `apt-get install -y <pkg>` if the package exists — verify first with `apt-cache policy <pkg>` (empty output = not in the distro repos → use native installer).
3. **Any OS**: language-native installer from the table above is the portable fallback.
4. **Windows**: prefer the language-native installer (npm/composer/pip); for standalone binaries check the tool's GitHub releases.

## Failure handling

- **Package manager missing** (no brew/apt) → use native installer directly.
- **Native installer needs network and fails** → stop that tool, report exactly what command failed and the error text. Move to the next tool.
- **Post-install re-check still fails** (e.g. PATH not refreshed for new shells) → try `export PATH="$PATH:$(npm bin -g 2>/dev/null)"` or re-source the profile once. Only report as failed after that attempt.
- Collect every failed install for the final report with the exact command the user can run later.

## Config-file rule

If the tool is installed but its standard config file is missing, offer to create a minimal one (`AskUserQuestion`, `Yes, write minimal config` / `No, use defaults`). **Never overwrite an existing config file.**

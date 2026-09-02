# Language & tool reference (canonical matrix)

This is the canonical per-language selection used by this skill. It comes from the project's own engineering docs (12 languages, one quality tool + one test framework each). **Never swap in a different tool for a listed language without asking the user.**

## Detection signals & tool selection

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

## Always-present frameworks (no install question)

These ship with the language toolchain — treat as present, skip the install ask:

- Go → `go test`
- Rust → `cargo test`
- Swift → `XCTest` (via `swift test`)
- C# → `.NET Analyzers` + xUnit resolver ship with `dotnet`; xUnit needs project templates but no global binary
- Java → PMD & JUnit resolve as Maven/Gradle plugins (requires the build tool only)

## Boundary rules for detection

1. A language counts as "present" when **at least one repo signal exists** OR the user confirms they work in it.
2. Do not assume a language from a stray file (one `*.js` in a Python repo is not a JS project).
3. If signals conflict (multiple languages legitimately present), treat all confirmed languages as in scope — this skill is explicitly multi-language.
4. When unsure, call `AskUserQuestion` to confirm the language list before configuring anything.

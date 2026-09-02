# Verify reference — run commands & smoke tests

Use this in Step 2 (verify each tool works) and when generating hook/CI content. Commands are canonical per language.

## Quality-tool run commands

| Language | Quality run |
|---|---|
| Python | `ruff check . && ruff format --check .` |
| JS/TS | `npx biome ci .` |
| Java | `mvn pmd:check` (or `gradle pmdMain`) |
| C | `cppcheck --enable=all --error-exitcode=1 src/` |
| C++ | `clang-tidy src -p build/ --checks='bugprone-*,performance-*'` |
| C# | `dotnet build -warnaserror` |
| Go | `golangci-lint run ./...` |
| Rust | `cargo clippy --all-targets --all-features -- -D warnings` |
| PHP | `vendor/bin/phpstan analyse src --level=8 --no-progress` |
| Ruby | `bundle exec rubocop` |
| Swift | `swiftlint lint --strict` |
| Kotlin | `./gradlew detekt` |

## Test-framework run commands

| Language | Test run |
|---|---|
| Python | `pytest -q` |
| JS/TS | `npx vitest run` |
| Java | `mvn test` (or `gradle test`) |
| C | `ctest --test-dir build --output-on-failure` (build first) |
| C++ | `ctest --test-dir build --output-on-failure` |
| C# | `dotnet test` |
| Go | `go test ./...` |
| Rust | `cargo test` |
| PHP | `vendor/bin/phpunit` |
| Ruby | `bundle exec rspec` |
| Swift | `swift test` |
| Kotlin | `./gradlew test` |

## Verifying "it works"

1. **Quality tool**: run its check on the real codebase. Exit 0 (pass) OR non-zero with real findings (report) **both prove it runs**. Only "command not found" / crash / zero output is a failure.
2. **Test framework**: run the test command.
   - Tests exist → run them; pass is success, real failures are the framework working (report them as findings, not tool failure).
   - Zero tests in the repo → create ONE throwaway smoke test in the framework's convention (e.g. `tests/test_smoke.py` asserting `1+1==2`), run it, confirm pass, then **delete the throwaway file**. Never leave it in the repo.
3. Record per tool: `✅ working` / `❌ skipped (reason)` / `⚠️ configured but verification failed (reason)`.

## Build-prerequisite boundary

- C/C++ need `cmake -B build && cmake --build build` before ctest/clang-tidy.
- C# needs `dotnet restore` implicitly before build/test.
- If the build itself fails for reasons unrelated to tooling, report it as "build prerequisite failed", not a tool failure.

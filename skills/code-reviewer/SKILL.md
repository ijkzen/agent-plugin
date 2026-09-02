---
name: code-reviewer
description: Use when the user asks to review code, check a diff for bugs or security issues, or validate code quality before merge.
disable-model-invocation: false
version: 1.0.0
---

# Code Reviewer

Guide for performing structured code review.

## When to use

- User asks "review this code/diff/PR"
- Pre-merge validation of changes
- Security or quality audit of a file, directory, or commit

## Review dimensions

1. **Correctness** — logic bugs, off-by-one, race conditions, error handling
2. **Security** — injection, secrets in code, unsafe deserialization, auth flaws
3. **Performance** — N+1 queries, unnecessary copies, blocking in hot paths
4. **Maintainability** — naming, duplication, dead code, complexity
5. **Tests** — are changes covered? are edge cases tested?

## Output format

```markdown
## Review: <target>
### Critical (must fix)
- [ ] <issue> — <location> — <why>
### Suggestions (should consider)
- [ ] <issue> — <location>
### Nitpicks (optional)
- <note>
### Verdict: <APPROVE | REQUEST CHANGES>
```

## Rules

- Cite exact file:line locations for every finding
- Distinguish real bugs from style preferences
- Verify claims against actual code — don't review from memory

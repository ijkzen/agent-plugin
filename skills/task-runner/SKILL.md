---
name: task-runner
description: Use when the user asks to run, plan, or track multi-step tasks, or when breaking down a large goal into executable steps.
disable-model-invocation: false
version: 1.0.0
---

# Task Runner

Guide for planning and executing multi-step tasks efficiently.

## When to use

- User asks to "run a task", "plan this", or "break this down"
- A goal requires 3+ sequential steps
- User wants progress tracking on a complex workflow

## Procedure

1. **Clarify the goal** — restate what success looks like in one sentence
2. **Break into steps** — list 3-8 concrete steps with clear completion criteria
3. **Order by dependency** — steps that unblock others come first
4. **Execute with verification** — after each step, verify the output is real (not assumed)
5. **Report progress** — summarize what was done, what's next, what was blocked

## Format

```markdown
## Task: <goal>
Status: in-progress
Steps:
- [x] Step 1: <done>
- [ ] Step 2: <next>
- [ ] Step 3: <pending>
Blocked by: <nothing | reason>
```

## Rules

- Always verify completed steps with real tool output (never assume success)
- If a step fails, report the error and propose an alternative, don't silently skip
- Keep the task list visible in the final response

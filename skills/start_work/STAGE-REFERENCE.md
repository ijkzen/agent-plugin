# Stage reference — boundaries, handoffs, error handling

Details behind `start_work`'s seven stages. Read the stage you are about to run before running it.

## Dependency availability (the global gate)

Referenced skills fall into two groups:

| Skill | Source | Availability check |
|---|---|---|
| grill-with-docs | in-repo | listed in available skills |
| to-spec | in-repo | listed |
| to-tickets | in-repo | listed |
| implement | in-repo | listed |
| tdd | in-repo | listed |
| code-review | in-repo | listed |
| ponytail | external plugin `ponytail` (DietrichGebert/ponytail) | `ponytail` skill callable (namespaced `ponytail:ponytail` or bare) |
| ponytail-review | external plugin `ponytail` | `ponytail-review` skill callable |

**If an external skill is unavailable** (plugin not installed):

1. Tell the user which one is missing and that it ships with the `ponytail` plugin (this plugin already declares it as a dependency).
2. `AskUserQuestion`: "The `ponytail` plugin isn't available. How should I proceed?" options:
   - `Install it` — run the plugin install path and retry the availability check once.
   - `Continue without it` — use only in-repo skills: Stage 1 refinement without the redundancy trim; Stage 5 review with `code-review` only (no over-engineering pass). Note in the final summary that the ponytail passes were skipped.
   - `Abort` — end the pipeline.

**Never** simulate ponytail's judgment with your own ad-hoc "keep it minimal" instructions if the skill is absent; either it runs or the pass is skipped and reported.

---

## Stage 1 — Refine requirements

### What to do

1. Invoke `grill-with-docs` with the user's raw request. It interviews the user (via `AskUserQuestion`) to sharpen the plan against relevant documentation. Let it ask its own questions; do not pre-answer.
2. On the sharpened result, invoke `ponytail` (or `ponytail:ponytail`) to force the laziest correct scope: YAGNI cuts, stdlib-over-dependency, removal of speculative asks.
3. **Boundary**: ponytail may propose deleting things the user explicitly wanted. If a trim contradicts an explicit user requirement, keep the requirement and note the conflict — do not silently drop.

### Handoff artifact

`REQUIREMENTS.md` (repo root, or `.scratch/start-work-<slug>/` if the repo forbids root clutter — check existing conventions first): one page stating scope, non-goals (the ponytail cuts), open questions resolved by grilling.

### Failure handling

- User gives no answer to grilling questions → cannot refine; stop and report, ask whether to proceed with the raw request as-is.
- `grill-with-docs` errors → retry once; if it still fails, proceed with raw request + note.

---

## Stage 2 — Write the spec

### What to do

Invoke `to-spec` with `REQUIREMENTS.md` as input. Follow its own template and publish target. It may re-ask about seams (its own `AskUserQuestion`) — let it.

### Handoff artifact

The spec file at the location `to-spec` chose (issue tracker per repo config, or a local spec doc). Record its path — Stage 3 and 4 need it.

### Failure handling

- `to-spec` unavailable → report and `AskUserQuestion`: skip spec (go straight to tickets from requirements) or abort. Skipping weakens Stages 3–4; say so in the question description.
- Spec rejected by user during to-spec's confirmation → return to Stage 1 (refine again); never force a spec.

---

## Stage 3 — Break into tickets

### What to do

Invoke `to-tickets` on the spec. It produces ordered, dependency-aware tickets (and quizzes the user on granularity via its own questions).

### Handoff artifact

Ticket list (per repo tracker config: local files under `.scratch/<slug>/issues/` or real tracker issues). Record the ordering + blocking edges.

### Failure handling

- Zero tickets produced (spec too vague) → report, ask user whether to re-run Stage 2 or hand-write tickets from requirements.
- User rejects granularity after repeated to-tickets iterations → accept their stated shape and proceed; do not loop forever (max 2 re-iterations, then take user's explicit direction).

---

## Stage 4 — Implement ticket by ticket (tdd)

### What to do

For each ticket **in dependency order** (frontier first, blockers before dependents):

1. Invoke `implement` for the ticket's work.
2. Invoke `tdd` discipline: one failing test (red) → minimal code (green) → repeat; vertical slices, tests at the agreed seams.
3. Only start the next ticket when the current one's tests pass and the diff is coherent.

### Handoff artifact

Working code + passing tests per ticket. Intermediate commits are optional — if committing per ticket, ask the user once at the start ("commit per ticket, or one commit at the end?"), don't re-ask every ticket.

### Failure handling

- A ticket cannot be implemented as specified (spec gap surfaced in code) → stop that ticket, report the gap, `AskUserQuestion`: `Adjust the spec and ticket` / `Skip this ticket` / `Abort`. Do not silently re-scope.
- Tests stay red after genuine attempts → report the failing test output verbatim; ask whether to continue to the next ticket or debug further. Never mark a red test as done.

---

## Stage 5 — Review

### What to do

On the complete diff (working tree vs the branch point):

1. Invoke `code-review` — correctness & standards axis (its own fixed-point question included).
2. Invoke `ponytail-review` (if available) — over-engineering axis: what to delete, reinvented stdlib, speculative abstraction. Complements code-review; both run, findings kept separate.

### Handoff artifact

Two finding lists (code-review: correctness; ponytail-review: deletable complexity), each item with file:line.

### Failure handling

- Either reviewer unavailable → see Dependency availability gate above.
- Review finds nothing (empty diff or pristine code) → record "no findings" and proceed to Stage 6 as a no-op.

---

## Stage 6 — Fix review findings

### What to do

1. Fix **critical** findings first (must-fix per each reviewer).
2. Fix **suggestions** unless the user objects — batch them and confirm once via `AskUserQuestion` if the set is large or invasive.
3. **Nitpicks**: ask before acting (`AskUserQuestion`, `Apply nitpicks` / `Skip nitpicks`).
4. Re-run the affected tests after fixes; re-review only the fix diff if a reviewer's concern was structural.

### Failure handling

- A "fix" breaks other tests → revert that specific fix, report the conflict, ask how to proceed. Do not paper over with test edits unless the test itself was wrong (verify first).
- User disagrees with a finding → leave the code as the user decides; note the disagreement in the summary. The user is the final arbiter.

---

## Stage 7 — Commit gate

1. `AskUserQuestion`: "Commit this work?" options `Yes, commit` / `No, leave changes` / `Yes, but split commits` (per-ticket commits if the user chose that in Stage 4).
2. On Yes: stage the relevant files, write a conventional commit message summarizing the feature (reference the spec/ticket ids where the tracker provides them). On `split`: one commit per ticket boundary.
3. On No: leave the working tree untouched and summarize what is pending.

### Failure handling

- Commit fails (hook rejection, conflicts) → report the exact error; if a pre-commit hook from `quality_engineering_assurance` blocks, fix the violation and retry (the hook is doing its job). Never `--no-verify` without asking.
- Nothing to commit (all changes already committed or reverted) → say so; do not create empty commits.

---

## Final summary shape

After Stage 7, output:

```
Request → refined (N questions, M cuts) → spec (<path>) → N tickets → implemented (all green) → reviewed (X correctness + Y over-engineering findings) → fixed → committed? yes/no
Skips/notes: <anything bypassed with user approval, e.g. ponytail passes>
```

Every skip must carry the user's explicit approval — never a silent skip.

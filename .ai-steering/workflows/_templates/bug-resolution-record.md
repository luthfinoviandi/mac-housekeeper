---
status: draft
work_item: {id}
status_checked: {YYYY-MM-DD}
note: {one line, no colon-space. Which gate this waits on, or the PR that implemented it}
---

# {Type} {id} — {short title} — Bug Resolution Record

> **Implementing the fix?** Read sections A, B and C. Stop at D. Section B names every file in scope and every file ruled out; if an anchor no longer matches, search for the quoted text. Fill in C's QA verification block once the change is made. If the record is wrong, stop and report.
> Process and rules: `.ai-steering/workflows/bug-resolution.md` and the project's half of it.

| | |
|---|---|
| **base_commit** | `{sha}` |
| **Phases 1–2 by** | {who / what, date} |
| **Phase 3 by** | {who / what, date} |

---

## A. Verdict
<!-- budget: 120 -->

**Symptom** — {what is observed, in the reporter's words.}
**Root cause** — {one sentence, naming the artifact where the invalid state originates.}
**Fix** — {one sentence.}
**Confidence** — {verified / inferred, and what would change the answer.}

## B. Fix Sheet

### In scope — read these, nothing else

- `{path}`

### Ruled out — do not re-open

<!-- fill: accepts `none`. -->

| Artifact | Why it is not the cause |
|---|---|
| `{path}` | {what was checked, and what the check showed} |

### Edits

<!-- fill: one row per edit site. Where an artifact exists once per environment, dialect, tenant or locale, one row per instance. -->

| # | Kind | Artifact | Anchor | Line @base | Change |
|---|---|---|---|---|---|
| 1 | source | `{path}` | `{symbol signature}` | {n} | {what changes, one line} |
| 2 | test | `{path}` | `{test class}` | end | add regression test `{name}` |

### Edit {n} — anchor and change

**Anchor** — {shortest unique existing text at the edit site. Per artifact kind: [`_anchors.md`](_anchors.md).}

```
{anchor text}
```

**Change**

```
{the replacement, the insertion, or a precise description of it}
```

**Why this site and not another** — {one line. Required where the obvious fix would have gone elsewhere.}

### Multi-instance fan-out

<!-- fill: the axis and every instance, or `single-instance`. -->

| Axis | Instances covered | Deliberately excluded, and why |
|---|---|---|
| {dialect / tenant / environment / locale} | {list} | {list, or `none`} |

## C. Verification

### Developer verification — proven before the pull request

**Reproduce the defect** — {the exact command or steps, and what a failing run looks like.}

```
{command}
```

**Prove the fix** — {the exact command, and the pass criterion.}

```
{command}
```

**Regression test** — `{test name}`. {Fails against `base_commit`, passes after the change; state once both have run.}

**Per-kind checks** — {the project's workflow file says what each artifact kind requires. Name the ones that apply and their result.}

**System map cards to update** — {`{path}`, or `none affected`.}

**Not verified** — {every check skipped, blocked or unavailable, and why.}

### QA verification — written in Phase 3, read by QA

<!-- fill: for someone with no checkout, no branch and no build. Every step is done in a running environment; every expected result is visible. A command that needs the repository belongs above. -->

**Where the fix lands** — {environment, and how QA confirms the build carries the change: pipeline, build number, image tag, deployment date.}

**Preconditions** — {tenant, product, user and role, test data or existing record and how to create one, configuration or feature flag.}

**What the defect looks like** — {the observable wrong behaviour. Where the old behaviour is still visible somewhere, say where.}

**Steps**

| # | Action | Expected after the fix |
|---|---|---|
| 1 | {what QA does} | {what QA sees} |

**Pass criterion** — {one sentence, observable, no code.}

**Instances QA must cover**
<!-- fill: one row per instance on every axis in section B's fan-out that QA can reach. -->

| Axis | Instances to test | Out of QA's reach, and why |
|---|---|---|
| {tenant / product / environment / dialect / locale} | {list} | {list, or `none`} |

**Also re-check** — {the neighbouring behaviour from section G's blast radius: screens, reports or flows, not classes.}

**Not testable by QA** — {what cannot be confirmed from outside, who verified each instead, and how. Accepts `none`.}

---
*Sections D onward are for the human reviewer and the pull request description. An implementing agent stops above this line.*

---

## D. Evidence

| Claim | How it was established | Verified / Inferred |
|---|---|---|
| {claim} | {the observation, the command, the log line} | verified |
| {claim} | {the reasoning, and what it rests on} | inferred |

**Instrumentation** — {temporary logging or probe added, and confirmation it was removed. `none` if none.}

## E. Causal chain
<!-- budget: 150 -->

1. **Observed** — {the symptom}
2. ← {what produced it}
3. ← {what produced that}
4. ← **Root cause** — {the first point where undoing the change prevents the symptom}

**Why the chain stops here** — {one line.}

**When it first broke** — {the commit, release or configuration change, or `unknown` and why it could not be established.}

## F. Options considered

<!-- fill: where only one option exists, say why the space is that narrow. -->

| Option | Blast radius | Risk | Verdict |
|---|---|---|---|
| A — {approach} | {files, instances, callers} | {what it could break, what it masks} | rejected — {why} |
| B — {approach} | {…} | {…} | **chosen** |

## G. Blast radius of the chosen fix
<!-- budget: 150 -->

- **Callers and consumers** of every changed artifact
- **Instances affected**: environments, dialects, tenants, locales
- **Data**: stored data changed, migrated, or left inconsistent
- **Contracts**: API shape, message schema, configuration key, or database column visible outside the change
- **Behaviour someone may depend on**, including behaviour that is wrong but relied upon

## H. Assumptions and open questions

**Assumption:** {stated here, never buried in prose above}
**Open question:** {what remains unanswered, and who can answer it}

---

## Reference — delete this section when the record is filed

**Fill comments** (`<!-- fill: … -->`) are instructions to the author. Delete every one before filing. **Budget comments** (`<!-- budget: N -->`) stay; the lint script reads them.

**Rules this template applies**, stated once in [../design-document.md](../design-document.md): Register, Budgets, File naming. Anchoring: [`_anchors.md`](_anchors.md).

**Sections that accept an empty answer** on one line: Ruled out, the fan-out (`single-instance`), Instrumentation, Not testable by QA. Not the developer verification block or Not verified.

**Statuses**: `draft` while investigating · `proposed` at a gate · `approved` once the Fix Sheet is accepted · `implemented` once merged, with `note` naming the pull request · `superseded` in the archive.

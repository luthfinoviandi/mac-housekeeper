---
status: draft
work_item: {id}
status_checked: {YYYY-MM-DD}
note: {one line, no colon-space. The design version tracked, and which gate this waits on or the pull requests that implemented it}
---

# {Type} {id} — {short title} — Implementation Plan

> **Executing this?** Read §0, §1, your phase, and §4. Every task names its artifact and its anchor; if an anchor no longer matches, search for the quoted text. Work not in a phase below is not in this change. A task resting on a §1 fact that is no longer true: stop and report.
> Process and rules: `.ai-steering/workflows/design-document.md` and the project's half of it.

| | |
|---|---|
| **Status** | {Proposed — executable once {gate} closes / Approved — executable} |
| **Design source** | {design document, its exact version, its status and approval date} |
| **base_commit** | `{sha}` |
| **Audience** | the developer executing this, and whoever raises the tasks |
| **Owns** | task breakdown, per-dialect DDL, code-level changes, test plan, sequencing |
| **Does not own** | the design. Where this plan and the design disagree, the design wins; report it in §1 |

<!-- fill: header rows are values, one line each. This plan carries current state only: no revision log, no change markers, no superseded rulings. -->

---

## 0. Scope
<!-- budget: 300 -->

### 0.1 In

<!-- fill: one row per change. Landing site and owner are stated here once. -->

| In | Where it lands | Owner — who merges it |
|---|---|---|
| {change} | `{module or path}` | {repository, layer or team} |

### 0.2 Out

<!-- fill: one line each. Where a reader would assume it is in, say where it went. Work that is real but not a developer's (a runbook, a write-up, an obligation on another owner) is one line with its destination. Deferred work keeps one line saying what brings it back. -->

### 0.3 Cross-boundary gates

<!-- fill: accepts `none — single repository, no gate`. The pointer, submodule or release that must move before the next phase can merge, and what is authorable in the gap. -->

## 1. Verified current state

<!-- fill: checked against the working tree at base_commit. Every task depends on these rows. -->

| # | Fact | Evidence | Verified / Inferred |
|---|---|---|---|
| V1 | {fact} | `{path}:{line}` | verified |

**Corrections to the design document**
<!-- fill: accepts `none`. Where investigation contradicted the design. Reported back to the design, not absorbed. -->

| # | Design says | Code says | Consequence for this plan |
|---|---|---|---|

## 2. Dependencies and blocking gates
<!-- budget: 200 -->
<!-- fill: accepts `none — nothing outside this plan blocks it`. Each dependency is a capability this plan needs, with a local identifier X1…Xn, stated as a testable yes or no. Never the other requirement's step or section numbers. Check identifiers do not collide with a product name. -->

| # | Capability this plan needs | Owner | Status | Blocks |
|---|---|---|---|---|
| X1 | {what must exist or be frozen} | {requirement or team} | {not delivered / in progress} | {phase or task, and what breaks without it} |

**Nothing starts until:** {the gates that must close first}

## 3. Phase {n} — {name}

<!-- fill: number phases and sections contiguously; adding or removing one renumbers everything after it. One sentence on what the phase delivers, then the task count. -->

{What this phase delivers.} {n} tasks.

### Task index

<!-- fill: task-level blocking lives in this table only. -->

| # | Task | Kind | Artifact | Blocked by |
|---|---|---|---|---|
| {P}{n}-1 | {what changes, one line} | source / test / schema / config / UI / manifest / process-def / data | `{path}` | — / {P}{n}-{m} / X{n} |

### {P}{n}-1 — {task name}

**Why** — {one line. The REQ- identifier or V row this task exists for.}

**Anchor** — {shortest unique existing text at the edit site. Per artifact kind: [`_anchors.md`](_anchors.md).}

```
{anchor text}
```

**Change**

```java
// {path}:{line} — before
{existing}

// after — {the one thing that must not be got wrong}
{replacement}
```

**Fan-out**
<!-- fill: where the artifact exists once per dialect, tenant, environment or locale, one block per instance, written out. State the axis and every instance, or state single-instance. -->

| Axis | Instances covered | Deliberately excluded, and why |
|---|---|---|

**Proven by** — {the test or command, and its pass criterion.}

**Not done by this task** — {where the obvious adjacent change belongs to another task. Omit where there is none.}

## 4. Test plan — mapped to acceptance criteria

<!-- fill: one row per acceptance criterion in the specification. -->

| REQ / criterion | Test | Level | Where it lives | Must fail before the change? |
|---|---|---|---|---|

**Performance and non-functional tests** — {the measure from the specification, as an assertion.}

**Manual verification** — {what cannot be automated, who does it, how they tell a changed system from an untouched one.}

## 5. Sequencing and deployment
<!-- budget: 250 -->
<!-- fill: phase-level only. Task blocking lives in each task index. -->

| Step | Phase | Blocked by | Releases with |
|---|---|---|---|

**Blast radius** — {what redeploys, restarts, changes data, or is visible outside the change.}
**Build** — {what is rebuilt or re-stamped, in what order.}
**Rollback** — {per phase, and what cannot be undone once data is written.}

## 6. System map cards to update

<!-- fill: `{path}` per card, against the tasks that make them stale, or `none affected`. -->

---

## Reference — delete this section when the plan is filed

**Fill comments** (`<!-- fill: … -->`) are instructions to the author. Delete every one before filing. **Budget comments** (`<!-- budget: N -->`) stay; the lint script reads them.

**Rules this template applies**, stated once in [`../design-document.md`](../design-document.md):

- Register, Budgets, File naming
- Stage 5: *Each requirement is isolated*
- Stage 6: *The implementation plan carries current state only*, *Numbering is current state*, *What an implementation plan holds*
- Anchoring: [`_anchors.md`](_anchors.md)

**Sections that accept an empty answer** on one line: §0.3, §1 corrections, §2, §6.

**Written on the task**, never in a section of their own:

- a deviation from a steering rule, in the words the developer needs at the edit site
- an open question that blocks the task, as *"no value is ruled; do not invent one"*

Both also stay recorded in the design.

**Effort is not a section.** Order and blocking are mandatory; days are not.

**Written from a reviewed design.** The design's review record exists before this plan is written.

**Statuses**: `draft` · `proposed` · `approved` · `in-progress` · `implemented`, with `note` naming the pull requests · `superseded`. Whoever merges the work moves the status and re-dates `status_checked`.

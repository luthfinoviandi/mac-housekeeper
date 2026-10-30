---
status: draft
work_item: {id}
status_checked: {YYYY-MM-DD}
note: {one line, no colon-space. Which gate this waits on, or the design document it fed}
---

# {Type} {id} — {short title} — Requirement Specification

> Process and rules: `.ai-steering/workflows/requirement-definition.md` and the project's half of it. Section D is the requirement set the design must satisfy. Downstream documents cite `REQ-` identifiers; a requirement discovered while designing is added here with a new identifier and passes Gate 2.

| | |
|---|---|
| **Gate 1 approved** | {who, date, or *pending*} |
| **Gate 2 approved (Ready)** | {who, date, or *pending*} |
| **Audience** | business analysts, the stakeholder, Compliance, the architect |

<!-- fill: header rows are values, one line each. No design, no schema, no task, no class or table names anywhere in this document. -->

### Revision log

<!-- fill: one row per version. Sections touched and identifiers added or withdrawn, 25 words. -->

| Version | Date | Change |
|---|---|---|
| v0.1 | {YYYY-MM-DD} | first draft |

---

## A. Problem
<!-- budget: 250 -->

**Need** — {what the requester cannot do today, in their own words.}

**Value** — {what changes for whom once this exists.}

**Origin** — {who asked, and what prompted it.}

**Solution as proposed** — {where the item arrived stating a mechanism, record it and mark it `constraint` or `candidate`. It does not enter section D.}

## B. Scope
<!-- budget: 300 -->

**Actors**

| Actor | Role in this behaviour |
|---|---|
| {who or what} | triggers / consumes / must never see |

**In scope**

- {one line each}

**Out of scope**

- {one line each, with the reason where it is not obvious}

**Affected deployment targets**
<!-- fill: the project's workflow file names the axes. One row per instance, or an explicit exclusion with its reason. -->

| Axis | Instances in scope | Excluded, and why |
|---|---|---|

**Steering conflict** — {`none`, or: which rule, which file, why the behaviour appears to need it, what the compliant alternative costs. Pending the lead architect's approval.}

## C. Open questions and assumptions

<!-- fill: a blocking question with no answer means the specification is not Ready. -->

| # | Question | Blocking? | Answer / assumption taken | Answered by, date |
|---|---|---|---|---|
| Q1 | {question} | yes / no | `Assumption:` {what was taken as true} | {who, date} |

## D. Requirements

<!-- fill: one row per requirement, one of the six patterns. Identifiers are stable: never renumbered, never reused. A withdrawn requirement keeps its row, marked `withdrawn`. -->

| ID | Pattern | Requirement | Priority | State |
|---|---|---|---|---|
| REQ-{id}-01 | ubiquitous | The {system} shall {response}. | must / should-have / could-have | active |
| REQ-{id}-02 | event-driven | When {trigger}, the {system} shall {response}. | | active |
| REQ-{id}-03 | state-driven | While {precondition}, the {system} shall {response}. | | active |
| REQ-{id}-04 | unwanted behaviour | If {trigger}, then the {system} shall {response}. | | active |

**Unwanted behaviour coverage**
<!-- fill: one row per failure mode considered, including those needing no requirement. A set with no unwanted-behaviour statements does not pass Gate 2. -->

| Failure mode | Covered by | Or: why no requirement is needed |
|---|---|---|
| {dependency unavailable} | REQ-{id}-04 | |
| {partial completion} | | {reason} |

## E. Acceptance criteria

<!-- fill: at least one per requirement; each names the test that proves it. Cite the identifier; do not restate the requirement text. -->

### REQ-{id}-01

```
Given {precondition}
When {action}
Then {observable outcome}
```

**Proven by** — {test name, or the inspection that settles it}

## F. Non-functional requirements

<!-- fill: same patterns, with numbers. A property a steering rule mandates is stated here explicitly. -->

| ID | Requirement | Measure | Source |
|---|---|---|---|
| REQ-{id}-NF01 | The {system} shall {response} within {limit}. | {how it is measured} | {steering rule, regulation, or the requester} |

## G. Traceability

<!-- fill: filled by the later stages. Empty cells are the coverage gaps. -->

| ID | Design section | Plan step | Test | Pull request |
|---|---|---|---|---|
| REQ-{id}-01 | §{n} | {step} | {test name} | {id} |

## H. Quality gate

<!-- fill: checked before Gate 2 is requested. The process file defines each characteristic. -->

**Per requirement** — necessary · appropriate · unambiguous · complete · singular · feasible · verifiable · correct · conforming

| ID | Fails any characteristic? | Which, and what was done |
|---|---|---|
| REQ-{id}-01 | no | |

**As a set** — complete · consistent · non-redundant · feasible · comprehensible · able to be validated

**Smell grep**
<!-- fill: record the hits and their justification. -->

| Term found | Where | Justified, or rewritten |
|---|---|---|

---

## Reference — delete this section when the specification is filed

**Fill comments** (`<!-- fill: … -->`) are instructions to the author. Delete every one before filing. **Budget comments** (`<!-- budget: N -->`) stay; the lint script reads them.

**Rules this template applies**, stated once in [../design-document.md](../design-document.md): Register, Every fact has one home, Budgets, File naming. Requirements are stated once, in section D; sections A, B and E cite the identifier.

**Sections that accept an empty answer** on one line: the steering conflict (`none`), section C, the smell-grep table. Not section D's unwanted-behaviour coverage.

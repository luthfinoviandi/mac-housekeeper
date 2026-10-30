---
status: draft
work_item: {id}
status_checked: {YYYY-MM-DD}
note: {one line, no colon-space. Which gate this waits on, or the design it fed}
---

# {Type} {id} — {short title} — Architecture Approach Document

> Process and rules: `.ai-steering/workflows/design-document.md` and the project's half of it. This document settles placement, boundaries, ownership and the decisions in section 15. Schema, payloads, rollback and troubleshooting belong to the companion technical design. Cite `REQ-` identifiers; a new requirement is a finding against the specification.

| | |
|---|---|
| **Status** | {Draft v0.1 / Proposed v1.0 / Approved v1.0, who, date} |
| **Scope** | {the feature or system boundary this document covers} |
| **Audience** | architects, the stakeholder, Compliance, business analysts |
| **Date** | {YYYY-MM-DD} |

<!-- fill: header rows are values, one line each. No justification, no restated rules. -->

---

## Document control

| Item | Value |
|---|---|
| Feature | {name} |
| Primary product | {product; name any second consumer} |
| Source requirements | {requirement specification path and version} |
| Related architecture | {other design documents this sits beside} |
| Companion artifacts | {technical design, implementation plan, and what each owns} |

### Revision log

<!-- fill: one row per version. Sections touched and identifiers taken or withdrawn, 25 words. Rationale lives in the D- row. -->

| Version | Date | Change |
|---|---|---|
| v0.1 | {YYYY-MM-DD} | first draft |

**Change markers.** Sections changed in this version are marked inline:
<mark>NEW v{n}</mark> added this version &nbsp;·&nbsp;
<mark>CHANGED v{n}</mark> revised this version &nbsp;·&nbsp;
<del>struck-through</del> <mark>REMOVED v{n}</mark> dropped this version, stub kept for one version.
Markers from earlier versions have been cleared — **anything unmarked is unchanged since v{n-1}.**

### Deviations from steering files

<!-- fill: `none`, or one row per rule broken. Pending until the lead architect approves. Stays across revisions. -->

| # | Rule | File | Deviation | Why the compliant path does not work | Cost carried | Status |
|---|---|---|---|---|---|---|

**Approval record**

| Who | When | What exactly was approved | Lapses when |
|---|---|---|---|

---

## 1. Executive summary
<!-- budget: 120 -->
<!-- fill: the decision, then the consequences that follow. For someone who reads nothing else. -->

## 2. Problem statement
<!-- budget: 250 -->

**2.1 What happens today**
<!-- fill: verified in code. -->

**2.2 What is wrong with it**
<!-- fill: in the requester's terms. -->

**2.3 What must not break**
<!-- fill: existing callers, contracts, tenants, behaviour. -->

## 3. Goals and non-goals
<!-- budget: 200 -->

**Goals**
<!-- fill: one line each, each citing a REQ- identifier. -->

**Non-goals**
<!-- fill: one line each, with the reason where it is not obvious. -->

## 4. Architecture overview
<!-- budget: 400 -->

**4.1 Placement**
<!-- fill: the module or service, and what the placement makes cheap and expensive. Cite the D- row for the rejected alternative. -->

**4.2 Ownership boundary**
<!-- fill: which repository, layer or upstream/downstream side owns each part, who merges it, what moves first. -->

**4.3 Flow**
<!-- fill: one diagram per cross-service and external flow, naming the payload and the failure behaviour at each hop. -->

```mermaid
sequenceDiagram
```

## 5. Component design
<!-- budget: 300 -->
<!-- fill: per component, four sentences: what it is, what it owns, what it calls, what calls it, the one thing easy to get wrong. Then what already exists and is reused, with evidence. -->

## 6. Data model — ownership
<!-- budget: 200 -->
<!-- fill: ownership and keys only. The schema belongs to the technical design; name it. Migration at the level of a decision: does existing data move, is the read path backward-compatible, what does it cost. Where this is the only document that will ever exist, the full schema goes here and this section says so. -->

| Table or store | Owning service | Key | Tenancy or partition column | Uniqueness that must hold |
|---|---|---|---|---|

**Owning document for the schema:** {path}

**Migration**

## 7. API design
<!-- budget: 150 -->
<!-- fill: every capability reachable from the external API. Where one is UI-only, say why. Shapes belong to the technical design. -->

| Operation | Surface | Auth | Notes |
|---|---|---|---|

## 8. Security considerations
<!-- budget: 250 -->
<!-- fill: which control sits where, and the backstop when it fails. Isolation model, injection surface, input validation, outbound content, sensitive-data exposure, override authority. Label any control that is target rather than current state. A control with no backstop is a risk in section 10. -->

## 9. Deployment and infrastructure
<!-- budget: 150 -->

**Blast radius**
**Ordering**
**Scope**
**Cost and latency**
**Rollback**
<!-- fill: one line: reversible, or precisely which part is not. -->

## 10. Risks
<!-- budget: 200 -->
<!-- fill: accepts `none` with its reason. -->

| # | Risk | Likelihood / impact | Mitigation | Owner |
|---|---|---|---|---|

## 11. Implementation sequence
<!-- budget: 200 -->
<!-- fill: phases in order. The task list is the implementation plan. -->

| Phase | Delivers | Blocked by | Validated by |
|---|---|---|---|

## 12. Requirement traceability

| REQ ID | Satisfied by § | Notes |
|---|---|---|

**Not covered by this design**
<!-- fill: one row per requirement left to another document or a later phase, with why. -->

| REQ ID | Where it goes | Why |
|---|---|---|

**Untraceable sections:** {`none`, or which} · **Uncited requirements:** {`none`, or which, and where they trace instead}

## 13. Open questions and assumptions
<!-- fill: accepts `none`. -->

| # | Question | Blocking? | Recommended answer | Answered by, date |
|---|---|---|---|---|

**Assumption:** {stated here, never buried in prose above}

## 14. Review record
<!-- budget: 300 -->

**Reviewers:** {who or what} · **Date:** {YYYY-MM-DD} · **Method:** {committee, second engineer, Stage 3 checklist}

| # | Finding | Severity | Disposition | Where it landed |
|---|---|---|---|---|

**Consequences of rejected findings**
<!-- fill: what the document now carries as a result, cited by D- identifier. -->

## 15. Decision log
<!-- fill: every decision and the alternative it rejected, once. Prose cites D-n. Where only one option existed, say why. -->

| # | Decision | Date | Decided by | Rationale — the fact that forces it | Alternative rejected, and its cost |
|---|---|---|---|---|---|

## 16. Appendices

**A. Referenced code**
<!-- fill: every file and symbol the claims rest on, with line reference at the stated commit. Verified and inferred separated. -->

**B. Steering files applied**

---

## Reference — delete this section when the document is filed

**Fill comments** (`<!-- fill: … -->`) are instructions to the author. Delete every one before filing. **Budget comments** (`<!-- budget: N -->`) stay; the lint script reads them.

**Sections that accept an empty answer** on one line, with no deviation and no approval: Deviations, §10, §13, and the "not covered" table in §12. Where any other section cannot be carried, record a deviation.

**Not carried here**: the schema, request and response payloads, per-dialect migrations, the per-phase rollback procedure, operator troubleshooting. All five belong to the companion technical design ([`design-document.md`](../design-document.md), *Every requirement gets a technical design*).

**Rules this template applies**, stated once in [`design-document.md`](../design-document.md): Register, Every fact has one home, Budgets, File naming, Change markers. Simplifications for a demo build are labeled inline with the production design beside them. Where build targets differ materially, each gets its own document. Read an existing approach document before drafting; the project's workflow file names them.

**Statuses**: `draft` · `proposed` · `approved` · `in-progress` · `implemented` · `superseded`, as defined in the deliverables folder's context file.

---
status: draft
work_item: {id}
status_checked: {YYYY-MM-DD}
note: {one line, no colon-space. Which gate this waits on, or the plan it fed}
---

# {Type} {id} — {short title} — Technical Design Document

> Process and rules: `.ai-steering/workflows/design-document.md` and the project's half of it. Section 4 is the design of record. Section 2 is the code as it is today at `base_commit`. Cite `REQ-` identifiers; a new requirement is a finding against the specification.

| | |
|---|---|
| **Status** | {Draft v0.1 / Proposed v1.0 / Approved v1.0, who, date} |
| **Design source** | {approach document and version, and which of its sections this expands. Or: none, technical design only} |
| **base_commit** | `{sha}` |
| **Audience** | technical leads, engineers, the reviewer, the business analyst, the architect signing it |
| **Date** | {YYYY-MM-DD} |

<!-- fill: header rows are values, one line each. No justification, no restated rules. -->

---

## Document control

| Item | Value |
|---|---|
| Feature | {name} |
| Owns | {schema / API contracts / configuration / process definition} |
| Does not own | {what is settled elsewhere, and where} |
| Source requirements | {requirement specification path and version} |
| Companion artifacts | {approach document, implementation plan, review record} |

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

| Who | When | What exactly was approved |
|---|---|---|

---

## 1. Overview
<!-- budget: 150 -->
<!-- fill: what is being built, and the one design decision a reader needs before section 4. Then what is excluded from this cut. -->

## 2. Current state — verified
<!-- budget: 400 -->
<!-- fill: every current-state claim and every path:line reference lives in this table. Later sections cite the V row. No appendix of referenced code. Prose here: only the constraints the rows impose, and live exposures found while designing that need their own work items. -->

| # | Fact | Evidence | Verified / Inferred |
|---|---|---|---|
| V1 | {fact the design depends on} | `{path}:{line}` at `base_commit` | verified |

**Constraints this imposes**

**Live exposures found while designing**

## 3. Requirements and coverage
<!-- fill: one table maps requirement to section to test. No second traceability table anywhere in the document. -->

### 3.1 Functional

| REQ ID | Satisfied by § | Test | State | Notes |
|---|---|---|---|---|
| REQ-{id}-01 | §{n} | {test name, or `—` and why} | met / **partially met** / **not met** | {only what the section refs do not say} |

### 3.2 Non-functional

| REQ ID | Property | Measure | Enforced at § | Test |
|---|---|---|---|---|

**Untraceable sections:** {`none`, or which} · **Uncited requirements:** {`none`, or which, and where they trace instead}

### 3.3 Amendments
<!-- fill: accepts `none`. Requirement changes agreed while designing, with who approved and when. -->

## 4. Detailed design

### 4.1 Service and component architecture
<!-- budget: 500 -->
<!-- fill: per component: responsibility, dependencies, threading or transaction model, ordering guarantee. Where reactive, blocking or mixed, say where the boundary is. -->

### 4.2 Database schema
<!-- fill: no budget. Every table, column, type, nullability, key, index and constraint.

Open with a storage narrative in prose, before the first table. Lead each paragraph with the claim in bold. Answer in this order:
- what one record is and which table holds it; what hangs off it and with what cardinality, in words
- which tables are the subject and which are the machinery (registries, queues, state tables)
- how the data gets in, where it is not a plain insert on the request path
- what is mutable and what is not, table by table where it differs
- what lives in another document's schema, naming the owning document

Every column table carries a Sample column:
- one worked example threaded through every table; a child's foreign key carries the parent's sampled key
- both values where one depends on shape or state
- long opaque values abbreviated, with the real width stated under the table
- samples illustrate; tests never read them
- never a real customer, tenant, member or document name; never anything that would be PHI or client data if real. Where the live value is sensitive, say so beside the benign sample. -->

```sql
```

**Per dialect**

| Dialect | Differences that matter here |
|---|---|

**Retention, growth and purge**
<!-- fill: how many rows, how fast, what removes them, and what the removal must not break. -->

### 4.3 API contracts
<!-- fill: request and response shapes at every boundary, with the error shape. DTOs at the boundary. Real payloads. -->

### 4.4 Process, workflow or rule design
<!-- budget: 300 -->
<!-- fill: accepts `not applicable — {reason}`. Element identifiers, routing, conditions, handler classes by fully qualified name. What the change does to callers already on the process. -->

### 4.5 Configuration

| Key | Default | Level | Runtime-changeable | Effect |
|---|---|---|---|---|

### 4.6 Identity, tenancy and authorization
<!-- budget: 250 -->
<!-- fill: where identity comes from, how far down it survives, what enforces isolation at each layer. Label any control that is target rather than current state. -->

## 5. Error handling
<!-- fill: keyed by the failure. Every fix and every operator instruction lives here. Section 10 cites the F row. -->

| # | Failure | Behaviour | Caller sees | Open / closed |
|---|---|---|---|---|
| F1 | | | | |

## 6. Testing strategy
<!-- budget: 200 -->

| Level | What it proves | Where it lives |
|---|---|---|
| unit | | |
| integration | | |
| negative-authorization | isolation holds when the caller is wrong | |
| performance | the non-functional measure in §3.2 | |

## 7. Rollout and rollback
<!-- budget: 250 -->

| Step | What deploys | Backward-compatible? | How it is undone | What cannot be undone once data is written |
|---|---|---|---|---|

**Data migration path**

## 8. Monitoring and observability
<!-- budget: 200 -->
<!-- fill: what is logged, at what level, with which correlation identifier; what is measured; what alerts, on what threshold; what is redacted and where. -->

## 9. Dependencies
<!-- fill: accepts `none`. -->

| Depends on | Kind | Status | Blocking? |
|---|---|---|---|

## 10. Troubleshooting
<!-- fill: keyed by the symptom the operator sees. The Failure column cites section 5; the Fix column carries only what F does not. A symptom with no F row is a missing failure mode or an operational cause outside this design. -->

| Symptom | Likely cause | Where to look | Failure | Fix |
|---|---|---|---|---|
| {what they see} | {cause} | {query, log line, or metric} | F{n} | |

## 11. Decisions
<!-- fill: every decision and the alternative it rejected, once. Prose cites D-n. -->

| # | Decision | Date | Decided by | Rationale — the fact that forces it | Alternative rejected |
|---|---|---|---|---|---|

## 12. Open questions and assumptions
<!-- fill: accepts `none`. -->

| # | Question | Blocking? | Recommended answer | Answered by, date |
|---|---|---|---|---|

**Assumption:** {stated here, never buried in prose above}

## 13. Review record
<!-- budget: 300 -->

**Reviewers:** {who or what} · **Date:** {YYYY-MM-DD} · **Method:** {committee, second engineer, Stage 3 checklist}

| # | Finding | Severity | Disposition | Where it landed |
|---|---|---|---|---|

**Consequences of rejected findings**
<!-- fill: what the document now carries as a result, cited by D- identifier. -->

**Declared gaps and compliance residuals**
<!-- fill: as they go to sign-off, in the language of the obligation, each cited by the REQ- row in section 3 that records it unmet. -->

## 14. System map cards to update
<!-- fill: `{path}` per card, or `none affected`. -->

## 15. Steering files applied
<!-- fill: which rules were checked against this design. -->

---

## Reference — delete this section when the document is filed

**Fill comments** (`<!-- fill: … -->`) are instructions to the author. Delete every one before filing. **Budget comments** (`<!-- budget: N -->`) stay; the lint script reads them.

**Sections that accept an empty answer** on one line, with no deviation and no approval: Deviations, §3.3, §4.4, §9, §12, §14. Not §4.2, §5, §8 or §10; where one of those cannot be carried, record a deviation.

**Variants.** Integration design and API design keep sections 1 to 3 and 11 to 15 and replace section 4. Name the variant in the title: `{Name}_Integration_Design_Document`, `{Name}_API_Design_Document`.

| Variant | Section 4 becomes |
|---|---|
| Integration design | integration context · system landscape · data flow · inbound and outbound contracts · authentication · retry strategy · data mapping · idempotency and deduplication · failover and circuit breaker |
| API design | resource model · endpoints · request and response schemas · authentication and authorization · error responses · pagination and filtering · versioning strategy · rate limiting · worked examples |

**Rules this template applies**, stated once in [`design-document.md`](../design-document.md): Register, Every fact has one home, Budgets, File naming, Change markers. Read an existing technical design before drafting; the project's workflow file names them.

**Statuses**: `draft` · `proposed` · `approved` · `in-progress` · `implemented` · `superseded`, as defined in the deliverables folder's context file.

# Design documents

> **Read when:** writing or revising any deliverable: architecture approach document, technical design document, implementation plan, requirement specification, review record, gaps register.

> **Binding steering file.** Rules here are hard constraints. Breaking one needs the lead architect's approval first. Agents: stop and tell the developer before deviating. See [Governance](../governance.md).

This file holds the process and the writing rules. It names no codebase. The project's own `workflows/design-document.md` adds the platform checklist, the filing locations and the documents that set the expected shape. Read both.

Co-author with the user. Curating each section with them is what makes the document decide something.

## The document is required

A design or architecture document must exist for the system. It covers how the system is architected, how each module works, how to troubleshoot common errors, and the full database schema: every table, column, key and index. See [../architecture-principles.md](../architecture-principles.md).

- Where build targets differ materially, each gets its own document. A local demo build and a production build are different architectures.
- A simplification made for a demo build is labeled as one, with the production design beside it. The format is in [../architecture-principles.md](../architecture-principles.md).

### Every requirement gets a technical design

No requirement is built without a technical design document. An approach document precedes it where placement or shape needs deciding first. Where placement is obvious, write the technical design directly.

| Document | Answers | Ends at |
|---|---|---|
| Architecture approach | Where the change belongs, what it touches, which shape was chosen and which were rejected | A decision |
| Technical design | The full schema, the contracts, the configuration, the failure behaviour, the rollout | A build |

Two rules:

1. An approved approach document closes nothing on its own. Stage 2 ends when a technical design exists and has been reviewed ([Stage 5](#stage-5--finalization)). A plan written from an approach document alone has skipped the stage.
2. This covers new functionality. A defect goes through [bug-resolution.md](bug-resolution.md) and produces a bug resolution record.

**The approach document stops where the technical design starts.** Deferring the schema, payloads, rollback and troubleshooting to the technical design is the rule.

| The approach document carries | The technical design carries |
|---|---|
| which service owns each table, the key, the tenancy column, the uniqueness constraints | every table, column, type, nullability, index and constraint, per dialect |
| the API surface: operation, surface, auth | request and response shapes, error shapes, real payloads |
| where each control sits, and what the backstop is | how each control is implemented, and what enforces it |
| blast radius, ordering, cost, and that a rollback exists | the rollback, per phase, and what cannot be undone |
| the risks the decision carries | the operator's troubleshooting table |

Where no approach document is written, the technical design carries all of it. Where an approach document is the only document that will ever exist, it carries the design detail too and says so. Record that case as a deviation.

Read an existing document before starting. The project's workflow file names the ones that set depth and structure. Match their shape. Write the prose by the [Register](#register).

## Audience

Every deliverable has one reader arriving with one question. Content that does not serve that question belongs in another document.

The question decides where content lives. Job title does not: two technical leads open the same design, one sizing a sprint and one reviewing a pull request, and want different halves of it.

| Deliverable | The reader's question | Who arrives with it |
|---|---|---|
| **Requirement specification** | *What must the system do?* | Business analyst, stakeholder, Compliance, architect |
| **Architecture approach document** | *Should we do this, and where does it sit?* | Architect, stakeholder, Compliance, business analyst |
| **Technical design document** | *What exactly are we building, and does it hold?* | Technical lead, engineer, reviewer, business analyst, the architect signing it |
| **Implementation plan** | *What do I do next, and can I start?* | The developer executing, and whoever raises the tasks |
| **Review record** | *Was it checked, and by what method?* | Anyone auditing the decision later |
| **Archive** | *What did this used to say?* | The next author |

**The section test.** Before writing or keeping a section, name its reader and what they do differently after reading it. If the honest answer is "the document owner keeps track of it", the section is coordination and leaves the document. Stages 4 and 6 apply this test; they do not restate it.

Three consequences:

- The business analyst reads the technical design. The coverage map and the declared-gaps table are written in requirement identifiers for them.
- Compliance and the sign-off signer are a distinct audience. Declared gaps, deviations and residual risks are written in the language of the obligation.
- The approach document exists for the readers deciding whether and where: the stakeholder, Compliance, the analyst. Where architects are its only readers, skip it and write the technical design.

Infrastructure, database administration and operations read none of these. A deliverable names a dependency on their work for its own reader. Hand the work to them directly.

## Register

Governs every deliverable. Templates cite this section and do not restate it.

Write for a person who has to act on the document. Concise points, active voice, clean layout, no filler.

### Sentences

- Twenty words or fewer. One idea each. Where a sentence runs longer, put a full stop before "and", "so" or "because".
- Active voice. Name the actor. "The drainer claims the row."
- Lead with the conclusion. Then the reasoning.
- Concrete over abstract. Say what is uncertain and why. Do not soften the sentence.
- One em-dash per paragraph at most. Prefer a full stop.
- Full sentences. Dropping articles and connectives makes the text shorter and harder to read.

### Paragraphs and layout

- One idea per paragraph. Short paragraphs. Four points is a list.
- Conditions, options, consequences and steps are lists.
- Repeating structure is a table: columns, failure modes, decisions, dependencies. Reasoning is prose.
- Subheadings inside any long section.
- Bold only where it changes what the reader does.

### What to cut

- Openers that restate the heading. Summaries of what follows. Closing paragraphs that repeat the section.
- Sentences about the document itself. Structure shows what each section owns; prose does not announce it. Phrases that do not appear in a filed document, full list in the lint script:
    - "this section", "this document carries"
    - "stated rather than omitted", "not an omission", "that is the rule"
    - "is the single home", "cited, not restated", "in those words"
    - "first-class reader"
- Negation pairs. State the rule: "List each exclusion." Leave out the failure it prevents. Name a failure only where it was observed, once, in a workflow file.
- Slogans and verdict sentences. "X wins", "worse than not doing it", "nobody executes a delta". They persuade a reader who already agreed and read as advocacy to one who did not.
- Advocacy. See the next section.

### Decision, then the forcing fact

- One sentence for the decision. One for the constraint that makes it non-optional. Stop.
- Keep the verified fact: an engine rule, a version, a measured number, a `file:line`. Cut the reasoning that walks from the fact to the conclusion.
- Rejected alternatives live in the Decisions table, once. Prose cites the `D-` identifier.
- State a consequence only where it changes what someone does: a test that proves less, a job that needs a different credential.
- Deliberation belongs in the review record or in the Decisions table's rationale column.

### Code is exempt

Code, SQL, configuration, payloads, error strings and file paths stay verbatim. Never reformatted, abridged or paraphrased.

### Every fact has one home

A fact is stated in exactly one section. Every other mention cites it.

| Fact class | Its one home | Everywhere else |
|---|---|---|
| requirement → design section → test | the technical design's requirements section | cite the `REQ-` identifier |
| current-state evidence: `path:line`, verified or inferred | the current-state table | cite the `V` row |
| decision, and the alternative it rejected | the Decisions table | cite the `D-` identifier |
| failure → behaviour → what the caller sees | the error-handling table | the troubleshooting table cites the `F` row |
| the schema | the technical design | the approach document names the owning document |
| deviation, and its approval | Document control, and the task it constrains in the plan | nowhere else |
| open question, and its ruling | the design | a blocked task states what the developer must not invent |

1. Never restate a table in prose.
2. Never open a section by repeating its heading.
3. Two sections keyed differently are not duplicates. Failures keyed by cause and symptoms keyed by what the operator sees both stay. The second carries only what the first does not.

### Budgets

Each template states a word budget per section as `<!-- budget: N -->`. The comment stays in the filed document and does not render. A section over its budget is cut. A section with no budget comment has none: the full schema, the migration set.

### Revision log rows

A row names the sections touched and the identifiers taken or withdrawn. Twenty-five words. Rationale lives in the `D-` row. A document carries no "corrections" section; the archive holds earlier versions.

### Lint

[lint-deliverable.mjs](lint-deliverable.mjs) checks a document against this register: leftover fill comments, a leftover Reference section, section budgets, sentence length, the banned phrases, em-dash density and revision-log row length.

```bash
node .ai-steering/workflows/lint-deliverable.mjs <file>
```

A non-zero exit means the document is not filed. Code fences and table rows are exempt from the sentence check.

## File naming

Every deliverable is named

```
{WorkItemType}_{WorkItemId}_{Name}.md
```

- **WorkItemType**: the tracking item's type exactly as the tracker names it (`Bug`, `Requirement`, `Enhancement`, `Task`, `Feature`, `Epic`).
- **WorkItemId**: the item's identifier, digits only.
- **Name**: the document's own name, words separated by underscores (`{Feature}_Architecture_Approach_Document`, `{Feature}_Technical_Design_Document`, `{Feature}_Implementation_Plan`, `{Feature}_Committee_Verdict`).

The prefix is the join key to the tracker. Two rules:

1. Pick the item the document is for. A plan for one requirement carries that requirement. A document spanning several children of one feature carries the feature. A design for a defect carries the bug. Where no work item exists, open one or ask the user to, before the file is created.
2. A superseded copy keeps its prefix when it moves to the archive, with the supersession suffix the project's workflow file defines.

The project's workflow file names the tracker, its type vocabulary, and any legacy documents exempt from this rule.

## Stage 1 — context gathering

Goal: close the gap between what the user knows and what the document needs. Exit when edge cases, alternatives and trade-offs can be discussed without re-explaining basics.

**Start from the requirement specification where one exists.** Design is the second of three stages: [requirement-definition.md](requirement-definition.md) settles what the system must do, this workflow settles how, and the implementation plan is the task list. Where a specification is `approved`, the problem, actors, scope, exclusions, affected instances and non-functionals are settled. Do not re-interview the user on them. Cite its `REQ-` identifiers in the requirements section. Limit questions to what is design-specific.

**A requirement discovered while designing is a finding against the specification.** Report it so it is added there with its own identifier and passes that workflow's approval gate.

Where no specification exists, gather the context below in full.

**Meta-questions**, asked as a batch, shorthand answers accepted:

1. **Document type**: architecture approach, technical design, integration design, API design, migration or refactoring.
2. **Scope**: which modules or services.
3. **Audience**: read it off the deliverable type. Ask only when a named reader sits outside the [Audience](#audience) table.
4. **Impact**: what decision the document supports.
5. **Constraints**: timeline, existing integrations, backward compatibility, tenant requirements.
6. **Related documents**: the project's workflow file says where existing documents live.

**Then gather domain context:**

- business requirements
- linked work items; [pr-review.md](pr-review.md) and its project companion say how to reach the tracker
- code patterns to follow
- technical constraints, data flows, external API contracts

**Investigate the codebase in parallel:**

- the module's dependency manifest
- service patterns in related modules
- configuration for the affected services
- existing schema migrations
- process or workflow definitions involved

**Then ask 5 to 10 targeted questions** about the gaps that remain.

**Ask rather than assume.** Shape each question so it can be answered "yes, option 1": recommend an approach and state the default. Where the space of answers is too wide to enumerate, say what your read is and ask what was intended. Where you must proceed before an answer, write **"Assumption: …"** in the document. Standard in [../architecture-principles.md](../architecture-principles.md).

## Stage 2 — structure and drafting

### Templates

Each artifact has a template in [_templates/](_templates/). Start from it. Do not reconstruct the shape from memory or keep a second copy elsewhere.

| Artifact | Template |
|---|---|
| Architecture approach: placement, boundaries, decisions | [_templates/architecture-approach-document.md](_templates/architecture-approach-document.md) |
| Technical design: schema, contracts, configuration | [_templates/technical-design-document.md](_templates/technical-design-document.md) |
| Integration design | the technical design template with section 4 replaced; its Reference section names the sections |
| API design | the technical design template with section 4 replaced; likewise |
| Implementation plan: the task list stage 3 produces | [_templates/implementation-plan.md](_templates/implementation-plan.md), current state only ([Stage 6](#the-implementation-plan-carries-current-state-only)) |
| Requirement specification: stage 1's artifact | [_templates/requirement-specification.md](_templates/requirement-specification.md), per [requirement-definition.md](requirement-definition.md) |
| Bug resolution record: defects | [_templates/bug-resolution-record.md](_templates/bug-resolution-record.md), per [bug-resolution.md](bug-resolution.md) |

Each template carries frontmatter, a document control block, the change-marker legend, deviation and approval tables, a review record and a closing Reference section. Instructions to the author sit in `<!-- fill: … -->` comments. **Delete every fill comment and the Reference section when the document is filed.** Budget comments stay.

**Frontmatter is YAML.** A colon followed by a space inside an unquoted value parses as a nested mapping and the file fails to load. Write the `note` value without `: `, or wrap it in double quotes. The same applies to a value containing `#`, a leading `[`, `{` or `*`, or a line break.

**A section a template asks for is not optional.** Where a document cannot carry one, record a deviation in the Deviations table with its cost, pending the lead architect's approval.

**Where the template marks a section *accepts `none`*, `none` or `not applicable — {reason}` on one line is the complete section.** No deviation, no approval. Load-bearing sections carry no such mark: the schema, security, error handling, monitoring, troubleshooting.

Templates hold the shape. Rules live in this file and in the project's half. Where a template and this file disagree, this file wins.

A rule stated here is cited by a template and never restated in one. A template's Reference section holds only what is specific to that artifact. Content the document emits lives in the template: the legend, the frontmatter, the section skeleton.

| Shared rule | Its one home |
|---|---|
| anchoring an edit site, and the anchor-by-kind table | [_templates/_anchors.md](_templates/_anchors.md) |
| the writing register | this file, [Register](#register) |

### Per section

1. Ask clarifying questions specific to the section.
2. Brainstorm 5 to 15 candidate points.
3. Curate with the user: keep, cut, combine.
4. Draft.
5. Refine with targeted edits.

Step 3 makes the document decide something.

Include real code (Java, SQL, YAML) where it clarifies. Reference actual modules, packages and patterns. Mermaid for diagrams: sequence for inter-service calls, class for data models, flowcharts for process logic. Numbered sections so a review can cite them.

## Stage 3 — validation

Check the design against these before showing it. The project's workflow file adds its platform checks. Both lists must pass.

- [ ] **Module boundaries**: each service owns its data.
- [ ] **API shape**: RESTful, DTOs at boundaries, entities never exposed.
- [ ] **External API coverage**: every capability is reachable from the API, not only the UI ([../architecture-principles.md](../architecture-principles.md)).
- [ ] **Security**: the full baseline in [../security.md](../security.md) and its project form. The Security section states which controls sit where. The design survives pen test, SAST and DAST clean.
- [ ] **Defense in depth**: every control has a stated backstop.
- [ ] **Data flows**: every cross-service and external flow has a diagram naming the payload and the failure behaviour at each hop.
- [ ] **Schema completeness**: every table, column, key, index.
- [ ] **Migrations**: planned for every dialect or engine the project ships, with the syntax differences documented.
- [ ] **Troubleshooting**: symptom, likely cause, where to look, fix. Written for the operator.
- [ ] **Simplifications flagged**: anything simplified for a demo or local build is labeled, with the production design beside it.
- [ ] **Patterns**: a recurring need is designed once and applied the same way. A deliberate one-off says why.
- [ ] **Isolation**: holds through the whole stack, and the design names which tenants, customers or accounts are affected.
- [ ] **Errors, logging, configuration, testing, deployment**: each addressed in the project's own idiom.
- [ ] **One home per fact**: no fact stated in two sections. The coverage map exists once. Troubleshooting repeats no fix text from error handling.
- [ ] **No table restated in prose.** No section opens by repeating its heading.
- [ ] **Budgets**: every section inside the word count its template states.
- [ ] **Lint passes**: `node .ai-steering/workflows/lint-deliverable.mjs <file>` exits zero.
- [ ] **Steering compliance**: the design breaks no rule in any steering location. Where it does, the deviation is recorded: rule, file, why the compliant path does not work, what the deviation costs, **pending the lead architect's approval**. In an implementation plan the deviation is attached to the task it constrains, in the words the developer needs.

## Stage 4 — reader testing

**Self-review** for internal consistency, contradictions, unstated assumptions, missing context for the stated audience, and generic filler.

**The redundancy pass has three steps.** Reading again for redundancy finds nothing, because the second copy reads correctly on its own.

1. Write down what each section owns, one fact class per section. A section that cannot be given one is two sections or nobody's.
2. Search the document for the second occurrence of each owned class. Requirement identifiers, `path:line` references, decision identifiers and failure names are greppable. A second hit outside the owning section is a citation or a defect.
3. Delete the copy. Leave the citation.

**Apply the [section test](#audience)** to every section.

**Predict 5 to 10 reader questions**, from a developer joining the team and an architect reviewing the proposal. Verify each is answerable from the document.

**Gap analysis**, the questions most often left unanswered:

- How does this interact with the services that already exist?
- What happens on failure, and on partial failure?
- How is it deployed, and rolled back?
- What is the data migration path?
- How does it affect existing tenants, customers or accounts?
- What monitoring and alerting is needed?

## Stage 5 — finalization

**Placement is project-specific.** The project's workflow file says which document type goes where. Ask when two locations are in use.

**A design document is a deliverable, not a steering file.** Editing it needs no approval. Any deviation it records stays recorded, with its approval, across revisions.

**Cross-reference** work items, existing architecture documents, relevant specs, external API specs.

**Remove the author instructions before filing.** Check rather than remember:

```bash
grep -rn "Reference — delete this section\|<!-- fill:" <repository-deliverables-directory>/
```

Anything that returns is unfinished.

### Each requirement is isolated

A deliverable states that it depends on another requirement and what capability it waits for. It does not carry that requirement's internal step numbers, section numbers or sequencing rationale. This binds hardest on an implementation plan, which is read in order to act.

1. Give every external dependency a local identifier, phrased as the capability needed, stated as a testable yes or no. Phases and tasks reference that identifier.
2. An obligation the other side owes this work stays here, because whoever executes it must know. Their internal ordering does not.
3. Check the identifiers do not collide with a product name. One document using `S3` for both a step and Amazon S3 is a defect.

The shape is in [_templates/implementation-plan.md](_templates/implementation-plan.md) § 2.

**Present with** the key decisions made, the open questions still needing resolution, and suggested next steps.

**Review before a plan is written.** A design is reviewed against the requirements it claims to satisfy and against the codebase it will be built in. The findings and their disposition are recorded before an implementation plan is written from it. How the review happens is open: a committee of agents, a second engineer, or a reviewer working the Stage 3 checklist. The record lives in the design document's Review section: reviewers, date, findings, disposition, gaps accepted with reasons. Programme-level verdicts spanning several documents keep their own file.

**Approval gate.** A document that deviates from any steering rule is not final until the lead architect approves the deviation. Say so when handing the document over. Record the approval in the document: who, when, what exactly.

## Stage 6 — revising an existing document

A revision is not a fresh draft. The reader reviews the delta, so the delta is visible without diffing two files.

**Every new version marks what changed and carries the legend that explains the marks.**

### The implementation plan carries current state only

No revision log, no change markers, no `<del>` strikethrough, no superseded rulings, no per-task note on what the task used to say. A plan is opened to do work. Everything else in this stage applies to every other deliverable.

1. Edit the task in place. Cite a decision only where the executor needs it to act.
2. Deleted work leaves the document, identifier included. Deferred work keeps one line in the scope section saying what brings it back.
3. Deviations and their approvals stay recorded: on the task each one constrains, and in the design.
4. The plan names the design document version it tracks, in its header. A plan tracking v6 of a design that is at v10 is visibly stale.

Where the superseded content exists nowhere else, archive it before overwriting and link the archived copy. Git is not a substitute when the change was never committed.

### Numbering is current state

Section numbers, phase numbers and task identifiers renumber whenever one is added or removed. A plan carries no holes and no register of retired identifiers.

**Never cite a plan's section, phase or task identifier from outside the plan.** They are positional labels, valid only for the version in front of you. A pull request, commit message, work-item comment, review record or design document refers to a task by its title and its work-item id.

**Design documents are the opposite.** Their decision, deviation, fact, assertion and interlock identifiers (`D-`, `DEV-`, `V`, `Q`, `I`) are durable and never reissued, because other documents cite them. Where one is withdrawn, its row stays and says so.

### What an implementation plan holds

A plan holds:

- scope and exclusions
- verified current state
- what it waits on
- the phases and their tasks, and their sequencing
- the test gate
- the system-map cards the change obliges the developer to update

Each of the following has a home elsewhere:

| Not in the plan | Where it goes |
|---|---|
| Declared gaps: requirements partially met or unmet | The design, in its compliance sign-off section |
| Deviations from steering rules | On the task each one constrains, and in the design's deviation table |
| A steering-compliance attestation | Nowhere. A developer is bound by the rules already |
| Residual risks carried to sign-off | The design, beside the declared gaps |
| Risks whose mitigation is "do this task first" | The task, or the sequencing section |
| Obligations on another requirement's owner | The design, as interlocks |
| Write-ups, specifications and proposals that produce no code | The design |
| Queries and runbook procedures no developer executes | The design, as the runbook page |
| Open questions and unruled decisions | The design. A task blocked by one says so in the task: *"no value is ruled; do not invent one"* |
| Retired identifiers | Nowhere |
| A section explaining why another section is missing | Nowhere. State an exclusion once, in the scope section |

Every removal names a destination. A deviation deleted without being attached to its task blocks the next pull request for following the convention the plan silently exempted it from.

The shape is in [_templates/implementation-plan.md](_templates/implementation-plan.md).

### Change markers

Markers are inline HTML. These documents are read in the VS Code Markdown preview and in Chrome, both of which render `<mark>` as a yellow highlight.

| Marker | Written as |
|---|---|
| **New** | `<mark>NEW v0.4</mark>` |
| **Changed** | `<mark>CHANGED v0.4</mark>` |
| **Removed** | `<del>` around the dropped row or heading, then `<mark>REMOVED v0.4</mark>` |

All three render the same yellow. The highlight makes a change findable; the word says which kind it is. `style` attributes are sanitised away by the VS Code preview, Azure DevOps and GitHub, so coloured markers are not possible.

Put the marker at the end of a heading, or at the start of a row or paragraph:

```markdown
### 5.5 Profile versioning <mark>CHANGED v0.4</mark>

<mark>NEW v0.4</mark> The pin delivers stability of evaluation, not retrospective explicability.

| <mark>NEW v0.4</mark> | `PROFILE_VERSION_ID` | pinned at first determination |
```

1. Scope the marker to the smallest unit that carries the change. A reworded row gets the marker on the row. A new subsection gets it on the heading.
2. Only the current version stays marked. Clearing the previous version's markers is the first step of a new revision.
3. Carry the version number in every marker: `NEW v0.4`, never bare `NEW`. It makes the markers greppable (`grep -n '<mark>' doc.md`).
4. `<mark>` and `<del>` only. `==highlight==` needs an extension the preview does not ship. Badge images from an external service render blank offline and tell a third party the document is being read.
5. `<del>` wraps a removed row or heading. Changed prose is replaced, never shown struck through beside its replacement.
6. The tag word carries the meaning: `NEW`, `CHANGED`, `REMOVED`, spelled out.
7. Markers are navigation. What changed and why belongs in the revision log row.
8. Never mark a section that did not change.

### Legend

Place the legend under the revision log in Document control:

```markdown
**Change markers.** Sections changed in this version are marked inline:
<mark>NEW v0.4</mark> added this version &nbsp;·&nbsp;
<mark>CHANGED v0.4</mark> revised this version &nbsp;·&nbsp;
<del>struck-through</del> <mark>REMOVED v0.4</mark> dropped this version, stub kept for one version.
Markers from earlier versions have been cleared — **anything unmarked is unchanged since v0.3.**
```

Name the actual versions.

### Revision log

The row for the new version names the sections it touched, within the [budget](#revision-log-rows):

```markdown
| **v0.4** | **2026-09-04** | Correlation moved to the AI `request_id` (§4.3). Close-out and quote due date added (§9a). Tenant-isolation state corrected (§6.1, §8.1). |
```

If a section number appears in the log, that section carries a marker. If a section carries a marker, the log accounts for it.

### What does not get cleared

Deviations, their approvals, and the consequences of rejected findings stay recorded across every revision. Clearing markers means clearing `<mark>` and `<del>` tags. The governance record underneath them stays.

## Invocations

```
"Write a design doc for the new notification service"
"Create an architecture approach document for the new integration"
"Continue with the design doc we started"
"Let's refine section 4"
"Check if this design doc follows our standards"
"Update the architecture document with the approved changes"   → Stage 6: bump the version, clear old markers, mark the new ones, refresh the legend
```

## The three stages

| Stage | Process | Artifact |
|---|---|---|
| 1 — requirement definition | [requirement-definition.md](requirement-definition.md) | the requirement specification |
| 2 — design | this file | the technical design, with its review record folded in, preceded by an approach document where the shape needs deciding first |
| 3 — implementation plan | this file | the implementation plan, the task list the work is executed from |

The implementation plan is the task list. Creating tracker items from it and executing it are bookkeeping and execution. The project's workflow file says what performs them.

A defect does not enter at stage 1. [bug-resolution.md](bug-resolution.md) applies instead.

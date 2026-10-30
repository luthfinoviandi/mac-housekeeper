# Requirement definition

> **Read when:** asked to define, clarify, refine, specify or "flesh out" a requirement, user story or enhancement — before any design work begins.

> **Binding steering file.** Rules here are hard constraints. Breaking one — in a specification, a design, or an edit to this file — needs the lead architect's approval first. Agents: stop and tell the developer before deviating. See [Governance](../governance.md).

**This file is the process. It names no tracker, no codebase, and no tooling.** Which tracker holds the item, which field the agreed criteria are written back to, and which axes make a requirement incomplete on a given platform live in that project's own `workflows/requirement-definition.md` in its steering folder. Read both: this one for how to work, that one for what the steps mean here.

The output shape is a separate file: [_templates/requirement-specification.md](_templates/requirement-specification.md). It is binding too — the section letters, the requirement identifier format and the trace table columns are a contract that the design workflow, the implementation plan and every downstream reviewer depend on, so changing them needs approval the same as changing this file.

## Where this sits

Requirement definition is the **first of three stages** every piece of new functionality passes through. Nothing else is a stage.

| Stage | Process | Artifact |
|---|---|---|
| 1 — requirement definition | **this file** | the requirement specification |
| 2 — design | [design-document.md](design-document.md) | the design document, with its review record folded in |
| 3 — implementation plan | [design-document.md](design-document.md) | the implementation plan — the task list the work is executed from |

**Applies to** the leaf items that describe behaviour: a requirement, a user story, an enhancement.

**Does not apply to** a parent item that only groups work — its children carry the requirements, and the parent keeps an approach document. **Nor to a defect**: a defect has no requirement to define, and its process is [bug-resolution.md](bug-resolution.md).

**This workflow writes no design, creates no tasks, and estimates nothing.** A specification that names a class, a table, a queue or a library has stopped being a specification.

## Principle

**What the system must do is settled and agreed before how it will do it is discussed.**

A design built on an unstated requirement is not wrong in a way review can catch — it is plausible, internally consistent, and answers a question nobody asked. The expensive failure is not a missing document; it is a design, a plan and a merged branch that satisfy an interpretation the requester never held. Splitting the work forces the behaviour to be stated, made verifiable and accepted while changing it still costs a sentence.

The specification is what crosses the boundary into stage 2. Not the conversation, not the ticket thread, not the agent's memory — the file.

## The phases

| Phase | Writes design or code? | Produces |
|---|---|---|
| 1 — Intake and clarify | **no** | specification sections A, B, C — problem, actors, scope, out of scope, open questions |
| **Gate 1** — the requester approves the problem and the scope | — | — |
| 2 — Specify | **no** | sections D to H — requirements, acceptance criteria, non-functionals, trace table, quality gate |
| **Gate 2** — the requester approves **Ready** | — | — |
| 3 — Hand off | — | nothing new; stage 2 begins from the specification |

Phases 1 and 2 may run in one context.

### Phase 1 — intake and clarify, and write nothing but the specification

**Separate the problem from the proposed solution.** Items arrive stating a solution — "add a column", "call their API nightly", "put a checkbox on the form". Record the proposal as a **constraint** if the requester holds it as one, or as a **candidate solution** to be decided in stage 2 if they do not. Do not carry it into section D as a requirement: a solution written into the requirement set removes the design stage's reason to exist.

**Name the actors.** Who or what triggers the behaviour, who consumes the result, and who must never see it. A requirement whose subject is "the system" and whose object is nobody in particular cannot be made verifiable later.

**State what is out of scope explicitly, in its own section.** An unstated exclusion is read as an omission by the next person and gets built.

**Ask rather than assume.** Where it is unclear how something should behave, the question goes to the requester — it is not resolved by picking an interpretation and writing it in as settled. Ask in a batch, shape each question so it can be answered "yes, option 1", and state the default you would otherwise take. Where the space of answers is too wide to enumerate, say what your read is and ask what was intended.

**Write `Assumption:` explicitly** where you must proceed without an answer. An assumption in section C is a question the requester can still overturn cheaply. The same guess buried in a requirement sentence is a defect with a long fuse.

**Check the requirement against the steering rules now, not at implementation.** If delivering this behaviour would require breaking a rule any steering file states, say so at Gate 1 — which rule, which file, why the behaviour appears to need it, and what the compliant alternative would cost. This is the cheapest point in the whole pipeline to discover it, and the most expensive one to skip.

**Do not design in this phase**, including sketching a schema, naming a component, or choosing between two mechanisms. Investigating what already exists in order to ask a better question is legitimate; writing the answer into the specification is not.

### Gate 1

Present the problem, the actors, the scope, the exclusions, the open questions and any steering conflict. Wait. If the scope is rejected, intake resumes — it does not proceed to requirement statements against a scope nobody accepted.

### Phase 2 — specify, and still write no design

#### Every requirement statement uses one of the six patterns

Statements follow EARS — the Easy Approach to Requirements Syntax, Mavin et al., first published at the IEEE Requirements Engineering conference in 2009. The value is not the house style; it is that each pattern forces the condition under which the behaviour applies to be written down.

| Pattern | Template |
|---|---|
| Ubiquitous | `The <system> shall <response>` |
| State-driven | `While <precondition>, the <system> shall <response>` |
| Event-driven | `When <trigger>, the <system> shall <response>` |
| Optional feature | `Where <feature is included>, the <system> shall <response>` |
| Unwanted behaviour | `If <trigger>, then the <system> shall <response>` |
| Complex | `While <precondition>, when <trigger>, the <system> shall <response>` |

The ruleset: **zero or many preconditions, zero or one trigger, exactly one system name, one or many responses**, with the clauses in that order.

- **One requirement per statement.** Two behaviours joined by "and" is two requirements, and it is the form that most often ships half-implemented.
- **`shall` is the only obligation word.** `should`, `may`, `could`, `will` and `is expected to` state nothing a reviewer can hold anyone to.
- **Name the system, not the developer.** The subject is the thing being built, never the person building it.

#### Unwanted behaviour is mandatory, not optional

**A requirement set with no `If … then` statements fails Gate 2.** Omitted failure paths are the documented largest source of requirement omissions and of the rework that follows, and they are the omission least likely to be noticed in review because nothing about the happy path looks incomplete.

For every external dependency, every input that can be absent or malformed, and every long-running operation, state what the system shall do when it fails — including on **partial** failure, where some of the work has already happened.

#### Acceptance criteria

Each requirement carries **at least one** acceptance criterion in Given / When / Then form, and each criterion names the test that will prove it. A criterion nobody can write a test for is a requirement that is not yet verifiable, which is one of the nine characteristics below and not a matter of taste.

#### Non-functional requirements are requirements

State them in the same patterns, with numbers. "Fast", "reliable" and "secure" are not requirements; a stated limit, rate, retention period or isolation guarantee is. Where a project's steering files mandate a non-functional property, the specification states it explicitly rather than relying on the rule being remembered — the project's own workflow file lists which ones.

#### Identifiers and traceability

Every requirement carries a stable identifier `REQ-{workItemId}-{nn}`, two digits, allocated in order.

- **Identifiers are never renumbered and never reused.** A withdrawn requirement stays in the table marked withdrawn; its number is retired.
- The identifier is quoted verbatim downstream: in the design document's section that satisfies it, in the implementation plan step that builds it, in the test that proves it, and in the pull request description.
- Section G carries the trace table, and section H records the quality gate below. It is what makes requirement coverage a join rather than a reading exercise — for the design review at stage 2, for verification at implementation, and for review asking which requirement a given diff serves.

#### The quality gate — nine characteristics per requirement

Each statement is checked against the characteristics ISO/IEC/IEEE 29148 defines. This is the checklist, not a summary of one:

| Characteristic | Fails when |
|---|---|
| Necessary | removing it costs the system nothing |
| Appropriate | it constrains the implementation instead of stating the need |
| Unambiguous | two competent readers can read it two ways |
| Complete | understanding it needs information that is not there |
| Singular | it states more than one behaviour |
| Feasible | it cannot be built within the known constraints at acceptable risk |
| Verifiable | no test, measurement or inspection could settle whether it holds |
| Correct | it does not actually represent the stated need |
| Conforming | it does not follow one of the six patterns |

**`Appropriate` is the one that does the work.** A requirement carrying implementation detail has quietly made the design decision, and the design stage then reviews a conclusion instead of reaching one.

The **set** is checked too: complete, internally consistent, non-redundant, feasible as a whole, comprehensible to the stated audience, and able to be validated by the requester.

#### The smell check — mechanical, and a flag rather than a verdict

Grep the specification for the linguistic constructs that indicate a violation of those characteristics:

| Smell | Terms |
|---|---|
| Unquantified | `all`, `always`, `every`, `never` |
| Ambiguous quantity | `most`, `many`, `several`, `some`, `sometimes`, `usually`, `normally`, `ideally`, `optionally` |
| Vague adjective | `easy`, `appropriate`, `user-friendly`, `fast`, `graceful`, `flexible`, `versatile`, `efficient`, `robust`, `adequate` |
| Vague verb | `handle`, `improve`, `provide`, `support`, `maximize`, `optimize`, `process` |
| Unresolved pronoun | `it`, `this`, `that` as the subject of a clause |
| Implied uncertainty | `should`, `can`, `could`, `may`, `if possible`, `as needed` |

Published detection of these constructs runs at roughly 0.59 precision and 0.82 recall, so **a hit is a question, not a defect** — `all` is correct when the set is genuinely closed. Recall is the useful half: a clean grep is weak evidence, a hit you cannot justify is a rewrite.

### Gate 2 — Ready

Present the requirement set, the acceptance criteria, the non-functionals, the assumptions still standing and the open questions still unanswered. Wait.

**Approval at Gate 2 means this is the behaviour that will be built and verified against.** It is not approval of a direction. A requirement the requester has not seen is not in scope, whatever the ticket says.

### Phase 3 — hand off

Stage 2 begins from the specification. The design workflow reads it instead of re-interviewing the requester, and the design's requirements section cites the `REQ-` identifiers rather than restating them in prose.

**A requirement that changes after Gate 2 is a change, not a correction.** Revise the specification in place, mark the change with the markers [design-document.md](design-document.md) defines for revisions, and state in the revision row which design or plan sections the change invalidates. A requirement quietly added to the set after the design was approved is the failure this workflow exists to prevent, arriving one stage later.

## Scaling down

Not every requirement deserves a specification file. **A requirement with one acceptance criterion, in one module, affecting one deployment target, with no schema change and no security surface, may skip the file** — write the requirement statements and their criteria into the tracker item itself, in the same patterns, and say that you skipped the file and why.

The exemption ends the moment any of these is true, and then the full process applies:

- more than one acceptance criterion, or more than one module
- the behaviour differs per environment, tenant, customer, locale, or storage engine
- data is modified, a schema changes, or a migration is involved
- it touches an API boundary, authorization, auditing, or anything the security standard covers
- it changes behaviour a published interface already promises
- the requester and the implementer are different people

**When in doubt, write the file.** The cost of an unnecessary specification is a short document. The cost of a skipped one is a design nobody can audit against an intent nobody wrote down.

## Filing

The specification is a deliverable, not a steering file. It lives in the deliverables folder, named for the work item it serves under the naming rule in [design-document.md](design-document.md); the project's own workflow file names the exact folder.

**One specification per work item, revised in place.** Intake, requirements and criteria accumulate in the same file across the phases; the frontmatter status is what moves. A specification replaced by a different understanding of the requirement is archived rather than overwritten.

**A requirement with no work item does not get a specification.** Open the item first — a deliverable no tracker points at is a deliverable nobody owns.

## Reporting

State, in this order: the problem, the scope and its exclusions, the requirement count and how many are unwanted-behaviour statements, the assumptions still standing, the open questions still unanswered, and any requirement you could not make verifiable.

**Never report a specification as Ready with open questions inside it.** An unanswered question in section C is a legitimate outcome that stops the work honestly; the same question left unmarked inside a requirement statement is a defect the design stage will inherit and the implementation stage will pay for.

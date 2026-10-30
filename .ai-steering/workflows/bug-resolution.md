# Bug resolution

> **Read when:** asked to investigate, diagnose or fix a defect: a bug, a production incident, a failing test nobody planted, "this used to work".

> **Binding steering file.** Rules here are hard constraints. Breaking one needs the lead architect's approval first. Agents: stop and tell the developer before deviating. See [Governance](../governance.md).

This file holds the process. It names no host, no codebase and no tooling. The project's own `workflows/bug-resolution.md` says which tracker holds the bug, how to reproduce, what proves a fix, and which artifact kinds the platform has. Read both.

The output is [_templates/bug-resolution-record.md](_templates/bug-resolution-record.md). Its section letters and table columns are a contract Phase 3 depends on. Changing them needs approval.

## Principle

Diagnosis and repair are separate jobs, done in separate contexts, with the user's approval between them. The record crosses the boundary. The conversation does not.

## The phases

| Phase | Writes code? | Produces |
|---|---|---|
| 1 — Investigate | no | record sections A, D, E: symptom, evidence, causal chain |
| **Gate 1** — the user approves the cause | — | — |
| 2 — Resolve | no | record sections B, C, F, G, H: options, chosen fix, the Fix Sheet, developer verification |
| **Gate 2** — the user approves the fix | — | — |
| 3 — Implement | yes | the change, its test, its map updates, and section C's QA verification block |

Phases 1 and 2 may run in one context. Phase 3 must not.

### Phase 1 — investigate, and write only the record

- **Reproduce first.** "Could not reproduce" is a legitimate outcome that stops the work. It is not a licence to guess at a fix.
- **Find the cause, not the line that threw.** Work backward from the symptom to the first point where state becomes wrong. Stop the chain at the first change that, undone, prevents the symptom.
- **Mark every claim verified or inferred.** An inferred cause is allowed. An inferred cause presented as verified is not.
- **Record what you ruled out, with the reason.** Phase 3 would otherwise re-search the same files.
- **Edit no code.** Temporary instrumentation is allowed; remove it before the phase ends and say so in the record.

### Gate 1

Present the causal chain and the evidence. Wait. A rejected cause returns the work to Phase 1.

### Phase 2 — propose, and still write no code

- **Give at least two options** wherever more than one exists, each with blast radius and risk. Recommend one.
- **Prefer the fix at the boundary where the invalid state entered** over a guard where it was noticed. Where the safe fix and the small fix differ, say so.
- **Write the Fix Sheet complete enough that Phase 3 never searches.** It names every file in scope and every file ruled out. Every edit site is anchored per [_templates/_anchors.md](_templates/_anchors.md). The verification command is stated.

### Gate 2

Present the Fix Sheet. Wait. Approval is of a specific set of edits.

### Phase 3 — implement from the record

**Start from a context that does not contain Phase 1.** A separate agent, a new session, a cleared conversation, or a fresh chat with only the record attached all qualify. Continuing in the same conversation does not.

- Read sections A, B and C. Stop at D.
- **Do not search the codebase.** Section B names every file in scope and every file ruled out. A file outside that list is a finding against the record. Stop and report it.
- **Relocate, do not re-investigate.** Confirm the base commit. Where the file has moved on, find each edit site by searching for its quoted anchor. One search per site.
- Every fix carries a regression test that fails before the change and passes after.
- Update the project's system map for every card the change touches ([../governance.md](../governance.md)).
- **Write section C's QA verification block.** The reader has no checkout, no branch and never read the investigation. Where the change has no externally observable behaviour, say so and name what proves it instead.

If the record is wrong, stop and say so. Return to Phase 1 and revise it. Do not repair the diagnosis from inside Phase 3.

## Artifact kinds

A defect fix is not always compiled source. The Fix Sheet carries a **Kind** column because anchor, verification and blast radius differ by kind. The project's workflow file enumerates its kinds. The anchor rules, the per-instance rule and the generated-artifact rule are in [_templates/_anchors.md](_templates/_anchors.md).

## Scaling down

A one-line, single-file, obviously correct fix with a test may skip Phases 1 and 2. Write the fix and say you skipped the record and why.

The exemption ends when any of these is true:

- more than one file, or more than one artifact kind
- the cause is not certain
- the artifact is multi-instance: per environment, dialect, tenant or locale
- data is modified, a schema changes, or a migration is involved
- the change touches an API boundary, authorization, or anything the security standard covers
- someone other than you will need to understand why the change was made

When in doubt, write the record.

## Filing

The record is a deliverable. It lives in the deliverables folder under the naming rule in [design-document.md](design-document.md), *File naming*. The project's workflow file names the folder. One record per defect, revised in place; the frontmatter status moves. A record superseded by a different diagnosis is archived.

## Reporting

State, in this order: the cause, the evidence, the fix, what you verified, what you did not.

- **Never report a fix as verified on a partial run.** Widen a narrowed build or test scope before reporting, and say which scope the result comes from.
- **Where a check was blocked, say so and say why.** A stated gap is information.

# PR review

> **Read when:** asked to review, preview, or check a pull request.

> **Binding steering file.** Rules here are hard constraints. Breaking one — in a design, an implementation, or an edit to this file — needs the lead architect's approval first. Agents: stop and tell the developer before deviating. See [Governance](../governance.md).

**This file is the process. It names no host and no codebase.** Which review tooling to use, and what the project-specific checks are, live in the project's own `workflows/pr-review.md` in its steering folder. Read both: this one for how to review, that one for what to look for here.

## Tooling

Establish how you can actually reach the pull request **before** starting, and prefer the richest route available: full PR metadata and threads, then a CLI against the host, then a local diff of the branch.

**Tell the user which route you took and what it could not cover.** Do not silently degrade from "review the PR" to "review a local diff" — a local diff has no PR description, no comment threads, and no linked work items, and a review that omits them is a different review.

The project's `workflows/pr-review.md` names the host, the tooling, and the fallbacks.

## Process

### 1. Gather

PR metadata (with changed files, labels, work-item references), the diff with line content, comment threads, linked work items, and the branch's commit history.

### 2. Understand before judging

Identify the purpose from the title, the description, and any linked work items. Group changes by kind — code, tests, configuration, data migrations, docs. Note the scope.

**Read the unchanged surrounding code.** Most real defects are inconsistencies with code the diff does not show.

While you have the file list, establish **which system-map cards the diff touches** — the map's `effects/CONTEXT.md` routes by kind of change, and each card's `entity:` line names the file it describes. You need this for the System map checklist below, and it is cheaper to work out now than after you have formed a view.

### 3. Review — the full-coverage rule

- **Check every file, not a sample.** Five correct files say nothing about the other ninety-five.
- **For bulk or templated PRs, build the full matrix of dimensions from the file list and verify at least one file from every cell.** Where a change is generated across several axes — environments, dialects, tenants, locales — the defects hide in the cells nobody opened. The project's file names its axes.
- **Never say "no issues found" without stating your coverage** — how many files of the total you checked, and which categories you did not.
- If the volume defeats you, say so upfront: *"This PR has N files. I verified X. Here is what I checked and what I could not."*
- **Copy-paste across the axes is the characteristic defect.** When one file is a sibling of another with values changed, verify the values match *its own* identity rather than the file it was copied from.

### 4. Cross-validate the couplings nothing enforces

Some couplings are not checked at build time, which makes review the only gate. The project's file enumerates its own; the discipline is the same in every case: **when two artifacts must agree and nothing verifies it, check both sides in the same review, and treat a one-sided change as incomplete.**

### 5. Post findings — only if asked

Posting a comment or a vote is outward-facing and visible to the team. **Confirm with the user before posting anything, including approvals**, unless they explicitly asked you to post. Read-only review is the default reading of "review this PR".

## Checklist

These categories apply to any repository. The project's `workflows/pr-review.md` gives each a concrete form and adds its own — **work both**.

**Architecture** — service boundaries respected; no cross-service data access; DTOs at boundaries; logic in services rather than controllers; constructor injection; no new circular dependencies; the change follows an existing pattern rather than being a one-off ([../architecture-principles.md](../architecture-principles.md)).

**Code quality** — language features used appropriately; boilerplate reduction that does not obscure; meaningful names; structured logging with correlation IDs; no PII, tokens, or passwords in logs. **Every new or modified function carries a comment** covering what it does, its inputs and outputs, and non-obvious behavior — a missing one is a review finding, not a nitpick.

**Security** — work the full checklist in [../security.md](../security.md) and its project-specific form. A security finding is a **blocker by default**, since production has to pass pen test, SAST, and DAST clean.

**API surface** — a new UI-facing capability is exposed on the API too; no UI-only endpoint ([../architecture-principles.md](../architecture-principles.md)).

**Testing** — tests for new logic; dependencies mocked in unit tests; Arrange-Act-Assert; positive *and* negative cases; a regression test accompanying every bug fix.

**Configuration** — structured configuration bound to typed objects; sensible defaults; deployment-template quoting rules observed.

**Steering compliance**
- the change obeys every rule in every steering location — a deviation is a **blocker** unless the PR description records the lead architect's approval for that specific deviation
- a PR that edits a steering file needs the architect's approval too, recorded the same way; approval by a peer reviewer does not substitute
- *"the existing code already does it this way"* does not clear a deviation in new code

**System map** ([../governance.md](../governance.md) — keeping the map current is mandatory, not optional)
- the diff touches a file named by a card's `entity:` → **that card is updated in the same PR.** A code change that leaves its card describing the old behaviour is **incomplete**, the same standing as a missing test
- a card that was updated carries `status: verified` with the **current** date and this branch's commit — a card edited but left stamped against an older commit is a finding
- a card the author knew was wrong and chose not to fix carries `status: stale`. That is allowed and honest; leaving it `verified` is not
- a **new** card, or a **new column, section, or frontmatter key** on an existing card, needs the architect's approval recorded in the PR description — content updates do not
- generated files are regenerated rather than hand-edited; the map's `_meta/` holds the scripts
- a new entity or process in the diff with **no** card at all is a gap worth raising — creating the card needs approval, so flag it rather than asking the author to add one unilaterally

## Output format

```markdown
## PR Review: #{number} — {title}

### Summary
What the PR does (1–2 sentences), overall assessment.

### Coverage
N files total; X verified. Categories checked: … Not covered: …
System map: cards affected / updated / not updated — or "none affected", stated explicitly rather than omitted.

### Blockers (Must Fix)
- **[Category]** `file:line` — issue and suggested fix

### Important (Should Fix)
- **[Category]** `file:line` — description and recommendation

### Suggestions (Nice to Have)

### Questions

### Recommendation
**Approve** / **Approve with Suggestions** / **Wait for Author** / **Request Changes**
[Brief justification]
```

The **Coverage** section is not optional decoration — it makes the full-coverage rule visible rather than assumed, and it is where an honest partial review is declared.

## Severity

| Level | Criteria | Action |
|---|---|---|
| Blocker | security issue, data-loss risk, breaks existing functionality, a defect that only manifests in an environment nobody tested, unapproved deviation from a steering file | must fix before merge |
| Important | missing tests, poor error handling, performance concern | should fix |
| Suggestion | style, naming, refactoring | nice to have |
| Question | unclear intent, design choice, missing context | needs clarification |

**An environment-specific defect is a blocker, not a nit.** Code that is wrong only for one dialect, one region, or one deployment target fails where nobody is looking, which is worse than failing everywhere.

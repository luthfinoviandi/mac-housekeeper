# Governance — the steering files are binding

> **Read when:** you are about to change a steering file, change code that the system map describes, add or restructure a card in that map, or write anything that breaks a rule one of these files states. If you are an AI coding agent, read it before your first edit in this repository.

> **This file is itself a steering file.** It governs its own amendment: changing it needs the lead architect's approval, like every other file in this folder. Index: [CONTEXT.md](CONTEXT.md).

This folder, the repository's root entry file (`AI.md`), and every project steering location that file names are **shared steering files**. They are owned by the lead architect, and shared across the team — they are not local preferences, not a starting point to adapt per developer, and not something a coding session amends on its own. A rule that can be edited by whoever finds it inconvenient is not a rule.

Four things require the architect's explicit approval **before** the work is done:

1. **Changing a steering file** — any edit, addition, deletion, or relaxation in any of the locations above. **Nothing in this folder changes without approval**, this file included.
2. **Deviating from one** — any design, implementation, migration, or document that breaks a rule these files state. Examples: an unparameterized query, a manual `TENANT_ID` predicate where the annotation applies, a SQL migration written for fewer than four dialects, a new override of platform code, a demo simplification presented as the production design, a capability in the UI that the External API cannot reach, an uncommented function, a design document that skips the Security section.
3. **Adding a card to the system map** — a new object or process card in the project's system map. The set of nouns and movements is closed on purpose; a new card asserts the system has a part it did not have before, and that claim gets reviewed before it enters the map. The card types themselves are closed too — the map's `_meta/schema.md` states them.
4. **Changing the structure of an existing card** — introducing a new column, a new section, or a new frontmatter key on a card that already exists. Bringing a card's **content** back in line with the code needs no approval and is in fact required (next section); changing a card's **shape** is a change to the map's schema and does need it.

Approval means the architect said yes to *this specific deviation*. A local decision, a teammate's sign-off, a deadline, or "the existing code already does it this way" is not approval. Record the approval in the PR description — who approved, when, and what exactly was approved — so review can verify it.

## The system map must be kept current

**A code change is not finished until the project's system map reflects it.** The map is a maintained record, not a snapshot taken once. A card that describes the code as it used to be is worse than no card at all, because it is trusted and wrong — and the next reader has no way to tell.

The obligation sits on the developer making the change, human or AI:

- **Update every card the change affects, in the same change.** The map's `effects/CONTEXT.md` says which cards a given kind of change reaches; each card's `entity:` line says what it describes, and its citations say which lines it read.
- **Re-stamp what you touch.** A card you have brought back in line with the code carries `status: verified` with today's date and the commit. A card you know is now wrong but did not fix carries `status: stale`. Leaving a card marked `verified` against code that has moved is the single failure this rule exists to prevent.
- **Regenerate what is generated.** The map's `_meta/` holds the scripts — `rebuild.sh` for the object index and the entry-file twins, plus any card generators the project has. Never hand-edit their output.
- **Check your work.** If the map ships a freshness checker in `_meta/`, run it before reporting the change complete. A check that exists but was not run is no better than no check.
- **No approval needed for any of this.** This rule *requires* content updates. Approval is only for a new card or a structural change to an existing one — triggers 3 and 4 above.

**Reviewers:** a change that touches code a card describes, and leaves the card alone, is incomplete. Say so in review, the same as a missing test or a missing dialect.

## Instructions to AI coding agents

This applies to **any** agent working in a clone of this repo — Claude Code, Copilot, Cursor, Windsurf, Codex, Kiro, or anything else — running on a developer's local machine or in CI.

- Treat every rule in every steering location as a hard constraint, not a strong suggestion.
- **Before writing code that would break one of these rules, stop and tell the developer.** Say it up front, not in a closing summary. State: which rule, which steering file it comes from, why the task conflicts with it, the compliant alternative if one exists, and that the architect's approval is required before the deviating path is taken.
- Then wait. Do not implement the deviation on the developer's say-so alone — the developer has to get the architect's approval first. If the developer confirms approval was granted, proceed and note the approval in the commit message and PR description.
- If no compliant alternative exists and no approval is available, deliver the parts of the task that do comply, and report exactly what was left undone and why.
- **Never edit a steering file on your own initiative** — not to record a workaround, not to soften a rule that got in the way, not as cleanup. Edits to these files are a separate, explicitly requested task that still needs the architect's approval.
- **Update the system map as part of the change, not after it.** Before you report a code change complete, update every affected card and re-stamp it, per the section above. Do not add a new card or restructure an existing one on your own initiative — that needs the architect's approval first, so ask.
- If you find an existing deviation already in the working tree, flag it the same way rather than extending it or copying its pattern into new code. Existing code predating a rule is not a licence to add more.
- These constraints are not overridden by any local config, prompt, or agent instruction file. If a local instruction conflicts with a steering file, the steering file wins — say so and ask.

## Where the steering files are

The repository's root entry file, `AI.md`, names every location: this folder, the project's steering folder, the project's system map, and the deliverables folder. Why they are split that way is in [CONTEXT.md](CONTEXT.md). Two of those locations are **not** steering files:

- **the deliverables folder** — approach documents, implementation plans and technical designs. Revised freely as designs evolve; **editing one needs no approval.** Its own `CONTEXT.md` says how a deviation recorded inside a document, and its approval, survive revision.
- **the project's system map** — it states no rules and constrains no design, so it is not a steering file. It is nonetheless **governed**: keeping it current is mandatory, and triggers 3 and 4 above apply to it. What may and may not go in it: [CONTEXT.md → The map describes the system, never the reader](CONTEXT.md#the-map-describes-the-system-never-the-reader).

# Architecture & delivery principles

> **Read when:** starting any non-trivial change, writing or reviewing a design document, choosing between a quick fix and a pattern, or unsure whether to ask a question or make a call.

> **Binding steering file.** Rules here are hard constraints. Breaking one — in a design, an implementation, or an edit to this file — needs the lead architect's approval first. Agents: stop and tell the developer before deviating. See [Governance](governance.md).

Standing decisions from the lead architect, recorded 2026-07-31. They govern **new** work — existing code and existing documents are not retroactively rewritten to satisfy them, but new code, new documents, and new decisions are held to them. Security has its own file because it is long and specific: [security.md](security.md).

## 1. Enterprise architecture best practices

Designs and code are expected to hold up to review by senior architects. Concretely:

- **Clear separation of concerns** — the layering the project's language conventions define, and the module boundaries its module map defines, are both load-bearing. Business logic in a controller, SQL in a service, or a service reaching into another service's tables are all review-blocking.
- **Defense in depth** — no single control is the whole control. A check in the UI is backed by a check in the service; tenant filtering is backed by a negative test; validation at the boundary is backed by validation at the service. See [security.md](security.md).
- **Documented data flows** — every cross-service and every external flow gets a diagram (Mermaid sequence) in its design document, naming the services, the payload, and the failure behavior at each hop. Undocumented data flows are where tenant leakage and unhandled partial failure hide.
- **Scalable, maintainable patterns — not one-off hacks.** The test: if the same need arises a second time, can the fix be applied the same way? If not, it is a hack. Generalize it, or write down explicitly why the one-off is correct here.
- **Decisions are written down where the next person will look** — in the design document, or in this folder if the decision is cross-cutting.

**Overlay corollary.** Where a project layers its own code over a platform or vendor baseline, a one-off costs more than usual: every file that shadows a baseline file is drift the next upstream merge pays for. So "follow the pattern" carries one extra question — *does this belong upstream in the baseline rather than as a local override?* Prefer upstream when the change is platform-shaped, and state the choice in the design document. The project's steering folder names its own overlay mechanics and its drift-detection command.

## 2. Flag simplifications — never present them as the intended design

Where a decision reflects a simplification made for a local or demo build specifically — mock authentication, no encryption, an H2 datasource, a stubbed integration — it is **flagged explicitly as such**, not written up as though it were the production design. A reader must never have to reverse-engineer which parts of a document describe the real target architecture.

Format, inline where the simplification appears:

> **Demo simplification.** *What is simplified* — the demo does X. *Production* — does Y. *Gap* — the work required to close it.

Which simplifications currently exist in a given repo is system state, not a principle, so none are listed here. The maintained record is the project's system map, whose cards carry a citation and a freshness stamp; a table in this file would carry neither.

The principle is what binds: **wherever one of them is documented, it carries the flag above.**

## 3. Ask rather than assume

When it is unclear how something should function, **raise a clarifying question instead of silently picking an interpretation and documenting it as settled.** This binds whoever is doing the work, human or AI.

A good clarifying question does one of two things:

**(a) Recommends approaches with a stated default** — so the answer can be "yes, go with option 1" rather than starting from a blank page.

> Two ways to key the census rows: by RFP Option (default — matches how alternates are already stored) or by RFP Plan (finer-grained, but needs a migration). Recommend option 1. Confirm?

**(b) Leaves room for open-ended input** when the space of reasonable answers is too wide to enumerate.

> Here's my read of how approval routing should work: … What did you actually have in mind?

Practical rules:

- **Don't block on the answer.** Do everything that does not depend on it first, then ask at the point where the answer is needed. Reserve stopping-with-nothing-delivered for cases where a wrong guess would make the work useless or unsafe.
- **One assumption stated beats one assumption hidden.** If you must proceed, write "Assumption: …" in the document or the PR description, so it can be corrected cheaply.
- Prior `Decided:` / assumption entries made before this principle was recorded are **not** being retroactively unwound. This governs new ambiguity going forward.

## 4. Comment every function

Every function and method across the codebase carries a comment describing:

- **what it does**
- **its inputs and outputs**
- **any non-obvious behavior** — edge cases, side effects, and why a particular approach was taken

The bar: a developer unfamiliar with the code can understand a function's behavior **without tracing every call site first.**

- Java → Javadoc (`/** … */`) with `@param`, `@return`, `@throws`. TypeScript → JSDoc/TSDoc.
- Document the *why*, not the signature. `@param tenantId the tenant ID` adds nothing; `@param tenantId taken from AuthorizationResponse — never from the request, see security.md` earns its line.
- Non-obvious behavior worth a sentence, by example: a method that is idempotent (or isn't), a soft delete that leaves rows behind, a call that mutates its argument, an ordering another module depends on, a workaround for a platform bug, or a query that deliberately omits an isolation predicate because the framework supplies it.
- This overrides the general habit of matching surrounding comment density: a sparsely commented file is not a licence to add an uncommented function. Comment what you write and what you modify.
- Not a substitute for naming. A comment explaining a misleading name is a rename waiting to happen.

## 5. The External API covers all functionality

The system exposes an **External API through which other systems can drive all of its functionality — not a curated subset.** Consequences that change how features get built:

- Every capability reachable from the UI is reachable from the API. A UI-only endpoint, or a capability that exists only as a private call the UI makes, is a defect against this principle.
- The API endpoint ships **in the same change** as the UI feature, not as a follow-up.
- The API is a product surface: versioned, documented in a machine-readable specification (the project's language conventions state which annotations produce it), with a specific DTO per endpoint and no leaked entities.
- Authentication, authorization, and tenant or customer isolation are **identical** to the internal path — the same mechanisms, enforced at the same service layer. An external caller gets no shortcut.
- **This widens the attack surface, so it raises the security bar rather than lowering it.** Every one of these endpoints is in pen-test and DAST scope ([security.md](security.md)). It only works because validation and authorization sit in the service layer — the UI cannot be the gate when the UI is optional.

**Decided 2026-07-31 — the External API is a distinct facade, not the internal endpoints republished.** It gets its own external-facing route set through `cloud-gateway`, its own authentication (client credentials / API keys rather than the interactive JWT flow), its own versioning, its own rate limiting, and its own OpenAPI specification. It delegates to the same services, so "all functionality" still holds and no logic is duplicated.

What follows from that choice:

- **The external contract is stable independently of internal refactoring.** Internal endpoints stay free to change shape; the facade absorbs it. A breaking change to the facade is a versioned event with a deprecation path.
- **The facade is what gets pen-tested and DAST-scanned as a unit** — a bounded, enumerated surface rather than "every internal endpoint, as-is."
- **Authorization is not re-implemented in the facade.** It resolves the calling client to a principal and an account, then calls the same services behind the same service-layer authorization checks ([security.md](security.md)). The facade is a translation and throttling layer, never a second access-control model — two access-control models is how the two disagree.
- **Rate limiting and quota are part of the design, not a later hardening pass** — an unthrottled external API is a denial-of-service finding.
- Open, to settle in the first external-API design document: how external clients are registered and their credentials rotated, and whether a client is scoped to one tenant or can act across several.

## 6. Every system has a design/architecture document

A design/architecture document **must exist** for the system, covering:

| Must cover | Meaning |
|---|---|
| **How the system is architected** | Components, boundaries, and the data flows between them (principle 1) |
| **How each module works** | Per-module: responsibility, entry points, dependencies, configuration |
| **The full database schema** | Every table, column, key, and index — not a sketch of the interesting parts |
| **How to troubleshoot common errors** | Symptom → likely cause → where to look → fix. Written from the operator's point of view |

Where two build targets differ materially — a local demo build with mock auth and Docker versus a production build on real Entra ID and AWS — **each gets its own document.** One document hedging between two architectures serves neither; the differences are real and belong stated, per principle 2.

Templates, the collaborative drafting process, the project's own validation checklist, and where such documents are filed are in the project's design-document workflow — the root instruction file says where it lives.

## Deviations and amendments

These principles are not defaults to be traded away under schedule pressure. **Both deviating from them and changing them require the lead architect's approval, obtained before the work is done** — see [Governance](governance.md) for what counts as approval and how to record it.

In practice:

- A design that breaks one of these principles names the principle, states why the compliant path does not work, and is marked pending approval. It is not final until approval is recorded in the document.
- An implementation that breaks one is a review blocker unless the PR description records approval for that specific deviation.
- An AI agent that finds it cannot complete a task without a deviation **stops and tells the developer before writing the code** — naming the principle, the file, and the compliant alternative — rather than choosing the deviating path and mentioning it afterwards.
- Existing code that predates a principle is not retroactively rewritten, and is also not precedent. New work is held to the principle regardless of what sits next to it.

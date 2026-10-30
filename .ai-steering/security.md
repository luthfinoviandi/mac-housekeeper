# Security baseline

> **Read when:** writing or reviewing anything that touches an API boundary, a database query, secrets, authorization, or session/cookie configuration — and before signing off the Security section of a design document.

> **Binding steering file.** Rules here are hard constraints. Breaking one — in a design, an implementation, or an edit to this file — needs the lead architect's approval first. Agents: stop and tell the developer before deviating. See [Governance](./governance.md).

**Decided 2026-07-31 (lead architect): security is a hard constraint, not a nice-to-have.** The production system must withstand rigorous penetration testing, SAST, and DAST with a clean result. This constraint informs every design decision — it is not a phase at the end, and "we'll harden it later" is not an acceptable answer in a design review.

**This file is the standard. It names no framework and no codebase.** How each rule below binds in a given repository — which ORM, which annotations, which known debt — is in that project's steering folder, in its own `security.md`. Read both: this one for what must be true, that one for what to type. Tenant or customer isolation mechanics are project-specific and live there too; **isolation leakage is a security defect, not a functional one.**

## The bar

| Gate | Clean means |
|---|---|
| **Penetration test** | No exploitable finding. Authorization bypass, tenant or customer crossover, and injection are all release-blocking. |
| **SAST** (static analysis) | No high or critical finding, and no suppression without a written justification reviewed by an architect. |
| **DAST** (dynamic analysis) | No high or critical finding against a deployed environment, scanning **every** exposed endpoint — including the External API surface required by [architecture-principles.md](./architecture-principles.md). |
| **Dependency scan** | No known-exploitable high/critical CVE in a shipped dependency, enforced in CI rather than checked by hand. |

## The seven non-negotiables

### 1. Parameterized queries everywhere — no string-concatenated SQL

- Every value reaching a query is **bound as a parameter**, never interpolated as text. Whatever the data layer offers for binding is the only permitted route; whatever it offers for raw substitution is prohibited.
- No string concatenation, no format-string assembly of SQL, in application code or in a query-definition file.
- Dynamic `ORDER BY` and column names cannot be bound. Validate them against a **server-side allowlist** of permitted names and map the client's value onto it. Never pass the client's string through.
- Iterating a collection into an `IN` clause is fine; the collection's *elements* must still bind.
- **Any raw-SQL surface that survives is the highest-risk thing in the system.** If one exists, the project's `security.md` names it, states what may be interpolated into it, and forbids extending the pattern. A query definition stored as data is still *code* and gets the same review scrutiny.

### 2. Strict input validation at every API boundary

- Validate at the boundary **and again in the service layer.** The boundary check protects HTTP callers; the service check protects every other caller — background workers, message consumers, scheduled jobs, internal callers.
- Validate **allowlist, not denylist**: enumerate what is acceptable and reject the rest. Denylists of bad characters are bypassable and count as a finding.
- Boundaries that are easy to forget and are all in DAST scope: path variables, query parameters, request headers, multipart uploads (content type, declared size, real size, filename), workflow or process variables, message bodies from any ingestion path, and any payload from an external integration.
- Reject unknown fields rather than silently ignoring them — an ignored field is a mass-assignment finding waiting to happen.
- Uploaded filenames are attacker-controlled: never use one to build a filesystem path or a URL without normalizing and re-anchoring it.

### 3. Secrets are never hardcoded and never logged

- No credential, token, key, connection string, or client secret in committed source, configuration, SQL, deployment values, or a test fixture. Configuration comes from environment variables and the platform's secret store.
- Never log passwords, tokens, authorization headers, PII, or regulated health or financial data. **Log identifiers, not payloads.** Regulated data carries its own audit requirements; the project states them.
- Exception paths leak the most: a stack trace or an error body must not carry a SQL fragment, a file path, an internal hostname, or a secret. Log the detail server-side and return a correlation ID.
- **Committed secrets already in a repository are debt, not permission.** The project's `security.md` records each one; the rules are do not propagate the value into a new file, do not add more, and rotate.
- - **Never write a credential into a deliverable**: not a record, specification, design or plan, and not as an illustrative example. Refer to it as coming from the password manager. A live secret found while working is reported with a recommendation to rotate.

### 4. Least privilege enforced at the data-access layer

Access control lives where the data is reached, not where the button is drawn.

- Authorization is enforced on the call that reaches the data, using the framework's own mechanism, and the acting identity comes from the **authenticated context** — never from a request parameter, header, or path variable. A client-supplied tenant, customer, or account identifier is an authorization bypass.
- The check sits at the **service** layer, not only at the controller. Every entry point into a service must pass the same check.
- **Hiding a UI control is not access control.** If the UI hides an action, the service must still refuse it. Assume every endpoint is called directly with a valid token belonging to someone else — that is exactly what a pen tester does.
- Each service owns its data with its own database credentials; no cross-service database access. A service's credentials should not be able to read another service's tables.

### 5. Secure session and cookie configuration

Every cookie the system issues carries `HttpOnly`, `Secure`, and an explicit `SameSite` (`Lax` unless a cross-site flow genuinely requires `None`, which then requires `Secure`). Missing flags are a standard DAST finding, cheap to fix, and cheap to forget.

Also in scope, and all DAST-visible: session and token expiry and rotation, logout actually invalidating server-side state, `Cache-Control: no-store` on responses carrying sensitive data, HSTS, and a restrictive CORS origin list — never `*` alongside credentials.

Where these are set upstream of the project's own code, the project's `security.md` says where to check and whether changing them is a platform change.

### 6. Dependency vulnerability scanning in CI

- A dependency scan runs on every build and **fails** it on a high or critical CVE, covering every package ecosystem the project ships.
- **Verify the scan exists before claiming this is satisfied.** The project's `security.md` records its current state and the command to check it — a date in a document is not evidence.
- A runtime or framework past end of support makes CVE triage a standing cost rather than a one-off: some findings are only fixable by pinning a transitive dependency. Record the pin and the reason.

### 7. No security through obscurity

- Assume the attacker has the source, knows the endpoints, and holds a valid token for some account.
- Unguessable URLs, hidden form fields, undocumented parameters, obfuscated identifiers, and client-side-only checks are not controls. **If removing the obscurity breaks the security, there is no security.**
- Identifiers that appear in URLs are enumerable, and a UUID is an identifier rather than an authorization token. Nothing may rely on either being secret.

## Review checklist

Use in PR review and design sign-off — the project's workflows say where. Each line has a project-specific form; take it from that project's `security.md`.

- [ ] Every query value bound as a parameter; no SQL assembled by concatenation or formatting
- [ ] Dynamic column and sort names resolved through a server-side allowlist
- [ ] Validation at the boundary **and** repeated in the service layer
- [ ] Path variables, query parameters, headers, and uploads all validated
- [ ] Acting identity taken from the authenticated context, never from the request
- [ ] Authorization enforced at the service layer; every entry point covered, not just the controller
- [ ] Any raw-SQL surface carries its required isolation predicate and interpolates nothing else
- [ ] No secret in source, configuration, SQL, deployment values, or a test fixture
- [ ] No password, token, PII, or regulated data in a log statement or an error response
- [ ] Error responses leak no internal detail — SQL, paths, hostnames, stack traces
- [ ] Cookies set `HttpOnly`, `Secure`, `SameSite`; CORS origins explicit
- [ ] New dependencies checked for known CVEs
- [ ] Nothing depends on an identifier being unguessable
- [ ] A **negative**-authorization test exists — cross-account access is asserted to *fail*

## Accepted gaps

A gap is accepted only when it is **written down, given a reason, and given an owner**. An accepted gap is never a licence to add another instance of the same problem.

Each project records its own in its `security.md`. This file records none, because a gap belongs to a codebase rather than to the standard.

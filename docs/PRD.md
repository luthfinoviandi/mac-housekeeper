---
status: approved
work_item: MHK-001
status_checked: 2026-10-15
note: Approved requirements using accepted project assumptions; technical design follows.
---

# PRD MHK-001 — MacHousekeeper MVP — Requirement Specification

> This requirement specification follows the requirement-definition workflow. It defines observable behaviour; implementation and architecture decisions belong in the next stage.

| | |
|---|---|
| **Gate 1 approved** | Lead architect, 2026-10-16 |
| **Gate 2 approved (Ready)** | Lead architect, 2026-10-16 |
| **Audience** | product owner, macOS users, technical lead, architect |

### Revision log

| Version | Date | Change |
|---|---|---|
| v0.1 | 2026-10-15 | Initial MVP problem, scope, requirements, and acceptance criteria. |
| v0.2 | 2026-10-16 | Deferred application removal to resolve the scope conflict with scan-only MVP behaviour. |
| v1.0 | 2026-10-16 | Gate 1 and Gate 2 approved by the lead architect. |

---

## A. Problem

**Need** — Mac users lack a focused terminal utility that helps them identify reclaimable storage and understand memory usage without requiring unsafe, broad deletion commands.

**Value** — A user can inspect large files, clean supported regenerable data, review applications that may no longer be used, and understand memory pressure. The user retains control over every destructive action.

**Origin** — Requested by the project owner as the first product definition for a new macOS terminal utility.

**Solution as proposed** — A macOS terminal application named MacHousekeeper. Swift with native macOS APIs is a candidate implementation choice, not a requirement of this document.

## B. Scope

**Actors**

| Actor | Role in this behaviour |
|---|---|
| Mac user | Starts scans, reviews findings, selects cleanup items, and confirms or cancels changes. |
| MacHousekeeper | Scans, reports findings, performs only confirmed eligible cleanup, and reports outcomes. |
| macOS | Provides filesystem, application, and memory information and may deny access to protected data. |
| User-owned data | Must not be removed merely because it is large, old, or associated with an application. |

**In scope**

- Read-only discovery of large files selected by a user-defined or product-default size threshold.
- Discovery of supported regenerable cache and junk categories.
- Preview of selected cleanup items before any mutation.
- Explicit, user-confirmed cleanup of eligible items.
- Reporting of item-level success, skip, and failure outcomes.
- Inventory of installed applications and evidence that may indicate an application is no longer used.
- Memory and swap status reporting with actionable, non-destructive advice.
- Human-readable terminal output and command-level failure signalling.

**Out of scope**

- Graphical user interface or menu-bar application.
- Windows or Linux support.
- Automatic deletion of arbitrary large files.
- Automatic application uninstallation.
- Forced RAM purging, memory compaction, or claims that the tool can directly increase available RAM.
- Cleanup of protected system locations, user documents, iCloud data, backups, browser profiles, or developer environments unless a later approved requirement explicitly adds a category.
- Duplicate-file detection, scheduled cleanup, cloud services, telemetry, or remote accounts.

**Affected deployment targets**

| Axis | Instances in scope | Excluded, and why |
|---|---|---|
| Operating system | macOS terminal on a local Mac | Windows and Linux are excluded from the MVP. |
| Execution privilege | Normal user account | Root or administrator execution is excluded from the MVP. |
| Interface | Interactive and scriptable terminal commands | GUI interfaces are excluded from the MVP. |
| Network | Offline/local operation | Network services and telemetry are excluded from the MVP. |

**Steering conflict** — Changing or adding `AI.md`, `CLAUDE.md`, or `.ai-steering/` requires lead-architect approval under the attached governance rules. This PRD does not modify those binding files. The compliant alternative is to obtain approval before adapting them for this repository.

## C. Open questions and assumptions

| # | Question | Blocking? | Answer / assumption taken | Answered by, date |
|---|---|---|---|---|
| Q1 | Is `MHK-001` the approved work-item identifier for this PRD? | no | `Assumption accepted:` use `MHK-001` as the project work-item identifier. | Project owner, 2026-10-15 |
| Q2 | What is the minimum supported macOS version? | no | `Assumption accepted:` target the current supported macOS release and one prior major release. | Project owner, 2026-10-15 |
| Q3 | Which cache categories are allowed in the first cleanup release? | no | `Assumption accepted:` include only categories proven to be regenerable and user-owned; exclude browser, developer, backup, and cloud-sync data. | Project owner, 2026-10-15 |
| Q4 | What evidence qualifies an application as a candidate for “unused”? | no | `Assumption accepted:` report evidence and confidence; do not classify an application as unused when usage evidence is unavailable. | Project owner, 2026-10-15 |
| Q5 | Should cleanup items be recoverable after confirmation? | no | `Assumption accepted:` provide a recovery path where macOS permits it; permanent deletion requires a separate approved requirement. | Project owner, 2026-10-15 |
| Q6 | What default threshold should the large-file scan use? | no | `Assumption accepted:` allow a user-provided threshold and define a documented product default during design. | Project owner, 2026-10-15 |
| Q7 | Should the MVP support machine-readable output for shell scripting? | no | `Assumption accepted:` require human-readable output and defer a stable machine-readable format. | Project owner, 2026-10-15 |

## D. Requirements

| ID | Pattern | Requirement | Priority | State |
|---|---|---|---|---|
| REQ-MHK-001-01 | event-driven | When the user requests a large-file scan, MacHousekeeper shall report files meeting the selected size threshold with their path, size, and modification date. | must | active |
| REQ-MHK-001-02 | event-driven | When a supported cleanup scan completes, MacHousekeeper shall report each eligible item with its category and estimated reclaimable size. | must | active |
| REQ-MHK-001-03 | event-driven | When the user requests an application scan, MacHousekeeper shall report each discovered application with its name, location, installed size, and available usage evidence. | must | active |
| REQ-MHK-001-04 | state-driven | While usage evidence for an application is unavailable or ambiguous, MacHousekeeper shall label that evidence as unknown or ambiguous rather than unused. | must | active |
| REQ-MHK-001-05 | event-driven | When the user requests memory status, MacHousekeeper shall report available memory indicators, swap indicators, and a timestamp for the observation. | must | active |
| REQ-MHK-001-06 | event-driven | When a scan completes, MacHousekeeper shall report the number of findings and the estimated size represented by each supported category. | should-have | active |
| REQ-MHK-001-07 | state-driven | While cleanup items are selected but not confirmed, MacHousekeeper shall present the selected items, the estimated reclaimable size, and the action required to cancel or confirm. | must | active |
| REQ-MHK-001-08 | event-driven | When the user confirms cleanup, MacHousekeeper shall remove only the selected items that are eligible under the approved cleanup categories. | must | active |
| REQ-MHK-001-09 | event-driven | When cleanup completes, MacHousekeeper shall report each selected item as completed, skipped, or failed and shall report the total logical size moved to Trash. | must | active |
| REQ-MHK-001-10 | unwanted behaviour | If the user does not explicitly confirm cleanup, then MacHousekeeper shall perform no cleanup mutation. | must | active |
| REQ-MHK-001-11 | unwanted behaviour | If an item is missing, inaccessible, protected, changed, or no longer eligible, then MacHousekeeper shall skip that item, report the reason, and continue processing other selected items. | must | active |
| REQ-MHK-001-12 | unwanted behaviour | If cleanup partially succeeds, then MacHousekeeper shall report the partial result and shall not describe skipped or failed items as reclaimed. | must | active |
| REQ-MHK-001-13 | unwanted behaviour | If the user selects an application for removal, then MacHousekeeper shall require explicit confirmation for that application before removing it. | must | withdrawn |
| REQ-MHK-001-14 | unwanted behaviour | If macOS denies access to a scanned location, then MacHousekeeper shall report the denied location and continue with locations that remain accessible. | must | active |
| REQ-MHK-001-15 | unwanted behaviour | If a requested scan cannot obtain reliable information, then MacHousekeeper shall report the limitation and shall not invent a finding or usage classification. | must | active |
| REQ-MHK-001-16 | ubiquitous | MacHousekeeper shall restrict cleanup to user-selected items from approved cleanup categories. | must | active |

**Unwanted behaviour coverage**

| Failure mode | Covered by | Or: why no requirement is needed |
|---|---|---|
| Cleanup starts without explicit confirmation | REQ-MHK-001-10 | |
| Item disappears or changes after preview | REQ-MHK-001-11 | |
| Some cleanup items succeed and others fail | REQ-MHK-001-12 | |
| Application usage evidence is missing | REQ-MHK-001-04, REQ-MHK-001-15 | |
| Application removal is requested | REQ-MHK-001-13 | Withdrawn from the scan-only MVP; retained as a safety requirement for a future approved removal capability. |
| macOS denies filesystem access | REQ-MHK-001-14 | |
| Scan cannot obtain reliable information | REQ-MHK-001-15 | |
| Protected or unapproved data is selected | REQ-MHK-001-16 | |

## E. Acceptance criteria

### REQ-MHK-001-01

```text
Given a readable file tree and a configured size threshold
When the user requests a large-file scan
Then every reported finding meets the threshold and includes a path, size, and modification date
```

**Proven by** — `LargeFileScanTests.reportsThresholdMatchesWithMetadata`

### REQ-MHK-001-02

```text
Given supported cleanup categories containing eligible items
When the user requests a cleanup scan
Then every reported eligible item has a category and estimated reclaimable size
```

**Proven by** — `CleanupScanTests.reportsEligibleItemsByCategory`

### REQ-MHK-001-03

```text
Given installed applications in the supported application locations
When the user requests an application scan
Then each result includes its name, location, installed size, and usage evidence field
```

**Proven by** — `ApplicationScanTests.reportsApplicationInventory`

### REQ-MHK-001-04

```text
Given an application with no reliable usage evidence
When the application scan completes
Then the result is labelled unknown or ambiguous and is not labelled unused
```

**Proven by** — `ApplicationScanTests.doesNotClassifyMissingEvidenceAsUnused`

### REQ-MHK-001-05

```text
Given a running supported Mac
When the user requests memory status
Then the output contains memory indicators, swap indicators, and an observation timestamp
```

**Proven by** — `MemoryStatusTests.reportsTimestampedMemoryStatus`

### REQ-MHK-001-06

```text
Given scan results in one or more categories
When the scan completes
Then the output contains an item count and estimated size for each category
```

**Proven by** — `ScanSummaryTests.reportsCountsAndSizes`

### REQ-MHK-001-07

```text
Given selected eligible cleanup items
When the user reaches the cleanup confirmation step
Then the output lists the selected items, estimated reclaimable size, and cancellation and confirmation actions
```

**Proven by** — `CleanupConfirmationTests.previewsSelectionBeforeMutation`

### REQ-MHK-001-08

```text
Given eligible items selected by the user and an explicit confirmation
When cleanup runs
Then only those selected eligible items are removed
```

**Proven by** — `CleanupExecutionTests.removesOnlyConfirmedEligibleItems`

### REQ-MHK-001-09

```text
Given a cleanup operation with item-level outcomes
When cleanup completes
Then the output reports each outcome and the total logical size moved to Trash
```

**Proven by** — `CleanupExecutionTests.reportsPerItemOutcomesAndActualSize`

### REQ-MHK-001-10

```text
Given selected cleanup items
When the user does not explicitly confirm cleanup
Then the filesystem remains unchanged
```

**Proven by** — `CleanupSafetyTests.doesNotMutateWithoutConfirmation`

### REQ-MHK-001-11

```text
Given a selected item that is missing, inaccessible, protected, changed, or no longer eligible
When cleanup processes the selection
Then that item is skipped with a reason and other selected items continue processing
```

**Proven by** — `CleanupSafetyTests.continuesAfterItemLevelFailure`

### REQ-MHK-001-12

```text
Given a cleanup operation where at least one item succeeds and at least one item fails
When cleanup completes
Then the result is marked partial and failed or skipped sizes are excluded from the logical size moved to Trash
```

**Proven by** — `CleanupSafetyTests.reportsPartialCompletionAccurately`

### REQ-MHK-001-13 (withdrawn)

```text
Given an application selected for removal
When the removal action is requested
Then the application is not removed until the user explicitly confirms that application
```

**Proven by** — Deferred until application removal enters an approved scope.

### REQ-MHK-001-14

```text
Given one scanned location that macOS denies and one scanned location that remains accessible
When the scan runs
Then the denied location is reported and the accessible location is scanned
```

**Proven by** — `PermissionHandlingTests.continuesAfterDeniedLocation`

### REQ-MHK-001-15

```text
Given a scan source that cannot provide reliable information
When the scan completes
Then the output reports the limitation and contains no fabricated finding or classification
```

**Proven by** — `ScanIntegrityTests.reportsUnknownInformationWithoutFabrication`

### REQ-MHK-001-16

```text
Given a selected item outside the approved cleanup categories
When cleanup is requested
Then the item is rejected and remains unchanged
```

**Proven by** — `CleanupSafetyTests.rejectsItemsOutsideApprovedCategories`

## F. Non-functional requirements

| ID | Requirement | Measure | Source |
|---|---|---|---|
| REQ-MHK-001-NF01 | The MacHousekeeper shall require explicit confirmation before any cleanup mutation. | Automated safety tests demonstrate no filesystem mutation without confirmation. | Product owner |
| REQ-MHK-001-NF02 | The MacHousekeeper shall run its MVP operations without requiring root privileges. | Clean-install execution test under a normal macOS user account. | Product owner |
| REQ-MHK-001-NF03 | The MacHousekeeper shall preserve item-level outcomes when one or more items cannot be processed. | Failure-injection tests verify complete outcome reporting. | Product owner |
| REQ-MHK-001-NF04 | The MacHousekeeper shall not send filesystem findings, application inventory, or memory observations over a network connection. | Static inspection and offline integration test. | Product owner |
| REQ-MHK-001-NF05 | The MacHousekeeper shall return a non-zero process status when a command-level failure prevents the requested operation from completing. | CLI integration tests assert exit status for invalid input and unavailable command operations. | Product owner |
| REQ-MHK-001-NF06 | The MacHousekeeper shall expose progress or an equivalent status indication for scans that exceed two seconds. | Timed integration test with a controlled large fixture. | Product owner |

## G. Traceability

| ID | Design section | Plan step | Test | Pull request |
|---|---|---|---|---|
| REQ-MHK-001-01 to REQ-MHK-001-16 | Technical Design §§3-5 | Implementation Plan P2-1 through P3-2 | acceptance-test names above | pending |
| REQ-MHK-001-NF01 to REQ-MHK-001-NF06 | Technical Design §§3-8 | Implementation Plan P1-2 through P4-2 | acceptance and non-functional tests | pending |

## H. Quality gate

**Per requirement** — necessary · appropriate · unambiguous · complete · singular · feasible · verifiable · correct · conforming

| ID | Fails any characteristic? | Which, and what was done |
|---|---|---|
| REQ-MHK-001-01 to REQ-MHK-001-16 | no | Each uses an EARS pattern, one observable behaviour, and a named acceptance test; reviewed at Gate 2. |
| REQ-MHK-001-NF01 to REQ-MHK-001-NF06 | no | Each includes a measurable verification method; reviewed at Gate 2. |

**As a set** — complete · consistent · non-redundant · feasible · comprehensible · able to be validated

The set is Ready. The project assumptions in section C are accepted for planning and design. REQ-MHK-001-13 is withdrawn from the scan-only MVP and remains reserved for a future removal capability.

**Smell grep**

| Term found | Where | Justified, or rewritten |
|---|---|---|
| `every` | REQ-MHK-001-01, REQ-MHK-001-02 | Justified as a bounded statement about every reported result; the implementation must define the scan result set. |
| `only` | REQ-MHK-001-08, REQ-MHK-001-16 | Justified as a safety boundary. |
| `available` | REQ-MHK-001-05 | Requires the design stage to define the concrete memory indicators and their unavailable state. |
| `reliable` | REQ-MHK-001-15 | Intentional product outcome; Q4 and the design stage must define the evidence rule. |

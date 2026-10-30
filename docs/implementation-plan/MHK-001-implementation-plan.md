---
status: in-progress
work_item: MHK-001
status_checked: 2026-10-16
note: P4-2 in progress; verification checklist and code-owned cache catalog are complete, with target-machine manual execution still outstanding.
---

# Implementation Plan MHK-001 — MacHousekeeper MVP — Implementation Plan

| | |
|---|---|
| **Status** | Approved — executable |
| **Design source** | [docs/technical-design/MHK-001-technical-design.md](../technical-design/MHK-001-technical-design.md), approved v1.0 by the lead architect on 2026-10-16 |
| **base_commit** | No commit yet; initial uncommitted repository state. |
| **Audience** | developer executing the work and whoever raises the tasks |
| **Owns** | task breakdown, source changes, tests, sequencing, and release verification |
| **Does not own** | product scope or architecture; the approved PRD and technical design remain authoritative |

## 0. Scope

### 0.1 In

| In | Where it lands | Owner — who merges it |
|---|---|---|
| Swift Package Manager executable and test target | `Package.swift`, `Sources/MacHousekeeper/`, `Tests/MacHousekeeperTests/` | MacHousekeeper repository |
| Typed CLI commands and human-readable output | `Sources/MacHousekeeper/CLI/` | MacHousekeeper repository |
| Large-file, cache, application, and memory read-only providers | `Sources/MacHousekeeper/Scanning/` | MacHousekeeper repository |
| Allowlisted, confirmed, recoverable cache cleanup | `Sources/MacHousekeeper/Cleanup/` | MacHousekeeper repository |
| Safety, failure, progress, and performance tests | `Tests/MacHousekeeperTests/` | MacHousekeeper repository |
| Development and manual verification instructions | `docs/` | MacHousekeeper repository |

### 0.2 Out

- GUI, menu-bar UI, Windows/Linux support, daemons, scheduled cleanup, network services, telemetry, and persistence remain out of scope per the approved PRD.
- Large-file findings are read-only; arbitrary large-file deletion is not implemented.
- Application scanning is read-only; application removal remains deferred under withdrawn `REQ-MHK-001-13`.
- Exact cache paths not included in the code-owned reviewed allowlist remain scan-only.
- Machine-readable output is deferred; human-readable terminal output is the current contract.

### 0.3 Cross-boundary gates

None — single repository, no external service or schema gate.

## 1. Verified current state

| # | Fact | Evidence | Verified / Inferred |
|---|---|---|---|
| V1 | The approved design defines a single local process with no persistence, network, or daemon. | `docs/technical-design/MHK-001-technical-design.md:49-53` | verified |
| V2 | Source belongs under `Sources/MacHousekeeper/` and tests under `Tests/MacHousekeeperTests/`. | `.ai-mac-housekeeper-steering/stack.md:18-23` | verified |
| V3 | Cleanup requires an allowlist, explicit confirmation, revalidation, no symlink following, and recoverable removal where possible. | `.ai-mac-housekeeper-steering/security.md:5-14` | verified |
| V4 | The repository has no `Package.swift`, source files, or test files yet. | `rg --files Sources Tests Package.swift` returns no matches at plan creation. | verified |
| V5 | The approved design maps active requirements to implementation sections and named tests. | `docs/technical-design/MHK-001-technical-design.md:60-105` | verified |

**Corrections to the design document**

None.

## 2. Dependencies and blocking gates

| # | Capability this plan needs | Owner | Status | Blocks |
|---|---|---|---|---|
| X1 | Swift 6.x and Swift Package Manager can build a macOS executable and test target. | Developer | not delivered | P1-1 and every later phase |
| X2 | The approved PRD and technical design remain unchanged while implementation proceeds. | Lead architect | approved | All phases; a requirement or design change returns to the design stage. |
| X3 | A supported macOS test machine is available for AppKit, metadata, permission, and memory verification. | Developer | not delivered | P2-3, P4-2 |

**Nothing starts until:** X1 is verified locally. X2 is a standing change-control gate. X3 may block only the platform-specific verification tasks; fixture-based unit work can proceed.

## 3. Phase 1 — package and CLI foundation

This phase creates the executable skeleton, typed command surface, and output/error contract. 2 tasks.

### Task index

| # | Task | Kind | Artifact | Blocked by |
|---|---|---|---|---|
| P1-1 | Create the SwiftPM executable and test target with no third-party dependency. | manifest/source/test | `Package.swift`, `Sources/MacHousekeeper/main.swift`, `Tests/MacHousekeeperTests/` | X1 |
| P1-2 | Implement typed command parsing, exit statuses, help, cancellation, and text rendering primitives. | source/test | `Sources/MacHousekeeper/CLI/` | P1-1 |

### P1-1 — Create package skeleton

**Why** — Establishes the approved Swift/macOS executable boundary for all functional requirements and NF02.

**Anchor** — New repository; no existing source anchor.

**Change** — Create `Package.swift` with one executable target and one test target. Set the minimum macOS platform to the current release plus one prior major release, using the toolchain available at implementation time. Create a minimal executable entry point that exits successfully and a test target that runs one smoke test.

**Fan-out**

| Axis | Instances covered | Deliberately excluded, and why |
|---|---|---|
| Platform | macOS target only | Windows/Linux are excluded by the PRD. |
| Dependency | Apple frameworks and Swift standard library | Third-party CLI parsers are excluded to keep the MVP small. |

**Status** — complete.

**Proven by** — `swift build` and `swift test` succeed on the supported development Mac.

### P1-2 — Implement CLI foundation

**Why** — Provides the stable terminal boundary for REQ-MHK-001-05, REQ-MHK-001-06, REQ-MHK-001-NF05, and REQ-MHK-001-NF06.

**Anchor** — New directory; no existing source anchor.

**Change** — Add command parsing for `scan large-files`, `scan caches`, `scan apps`, `memory`, and `clean caches`. Parse size thresholds and paths as typed values with explicit bounds. Add human-readable headings, summaries, warnings, cancellation handling, and non-zero command-level exit statuses. Do not add JSON output, config files, or arbitrary command execution.

**Fan-out**

| Axis | Instances covered | Deliberately excluded, and why |
|---|---|---|
| Output | Human-readable terminal output | Machine-readable output is deferred. |
| Invocation | One command per process | Daemon and background modes are excluded. |

**Proven by** — CLI integration tests reject malformed options, display help, return non-zero status for command failure, and preserve cancellation without mutation.

**Status** — complete. Interrupts currently retain the operating system’s default process cancellation behaviour; long-running provider cancellation is handled with the scan coordinator in Phase 2.

## 4. Phase 2 — read-only providers

This phase implements read-only models, traversal, findings, summaries, application inventory, and memory status. 4 tasks.

### Task index

| # | Task | Kind | Artifact | Blocked by |
|---|---|---|---|---|
| P2-1 | Add finding, evidence, summary, provider, and progress models. | source/test | `Sources/MacHousekeeper/Scanning/Models.swift` | P1-2 |
| P2-2 | Implement large-file and reviewed-cache scanning. | source/test | `Sources/MacHousekeeper/Scanning/FileScanner.swift`, `CacheScanner.swift` | P2-1 |
| P2-3 | Implement application inventory and evidence classification. | source/test | `Sources/MacHousekeeper/Scanning/ApplicationScanner.swift` | P2-1, X3 |
| P2-4 | Implement memory status and scan orchestration. | source/test | `Sources/MacHousekeeper/Scanning/MemoryReporter.swift`, `ScanCoordinator.swift` | P2-1, P2-2, P2-3 |

### P2-1 — Add scanning models

**Why** — Creates the shared result contract used by REQ-MHK-001-01 through REQ-MHK-001-06 and REQ-MHK-001-15.

**Anchor** — New directory; no existing source anchor.

**Change** — Define command-local findings, eligibility, evidence states, scan summaries, item-level warnings, and progress events. Keep paths as URLs internally and format them only at the output boundary. Represent unknown evidence explicitly.

**Proven by** — Unit tests construct each result state and verify stable summary aggregation without filesystem access.

**Status** — complete.

### P2-2 — Implement large-file and cache scanning

**Why** — Delivers REQ-MHK-001-01, REQ-MHK-001-02, REQ-MHK-001-06, REQ-MHK-001-14, REQ-MHK-001-15, and NF06.

**Anchor** — New provider files; no existing source anchor.

**Change** — Use Foundation filesystem enumeration without following symbolic links. Large-file scanning accepts only typed, bounded roots and thresholds. Cache scanning uses a code-owned reviewed allowlist of user-owned regenerable categories; unknown locations are reported as scan-only. Emit progress at the configured interval and continue after independent permission errors.

**Proven by** — Temporary-directory tests verify threshold matching, metadata, denied-location continuation, symlink rejection, cache eligibility, summary counts, and progress output.

**Not done by this task** — Cleanup mutation belongs to P3-1 and P3-2.

**Status** — complete.

### P2-3 — Implement application inventory

**Why** — Delivers REQ-MHK-001-03, REQ-MHK-001-04, REQ-MHK-001-14, and REQ-MHK-001-15.

**Anchor** — New provider file; no existing source anchor.

**Change** — Scan `/Applications` and `~/Applications`. Read bundle name, identifier, location, and installed size. Obtain optional usage evidence through a controlled macOS metadata provider; classify missing or ambiguous evidence as unknown or ambiguous. Never label an application unused solely from missing data.

**Proven by** — Fixture application bundles and macOS manual verification cover metadata, size, evidence states, denied roots, and unavailable metadata commands.

**Not done by this task** — Application removal is withdrawn and must not be added.

**Status** — complete.

### P2-4 — Implement memory reporter and coordinator

**Why** — Delivers REQ-MHK-001-05, REQ-MHK-001-06, REQ-MHK-001-15, NF04, and NF06.

**Anchor** — New provider and coordinator files; no existing source anchor.

**Change** — Read physical memory through Foundation and obtain supported memory/swap indicators through absolute executable paths passed as separate `Process` arguments. Capture an observation timestamp. The coordinator selects providers, aggregates results, emits progress, and maps unavailable indicators to explicit limitations.

**Proven by** — Parser unit tests, unavailable-command tests, offline-operation tests, and manual verification on a supported Mac.

**Status** — complete.

## 5. Phase 3 — safe cleanup

This phase adds the explicit preview, revalidation, recoverable cleanup, and per-item outcome flow. 2 tasks.

### Task index

| # | Task | Kind | Artifact | Blocked by |
|---|---|---|---|---|
| P3-1 | Implement allowlist policy and pre-mutation revalidation. | source/test | `Sources/MacHousekeeper/Cleanup/CleanupPolicy.swift` | P2-2 |
| P3-2 | Implement preview, confirmation, recoverable removal, and result reporting. | source/test | `Sources/MacHousekeeper/Cleanup/CleanupExecutor.swift`, `CleanCommand.swift` | P3-1, P1-2 |

### P3-1 — Implement cleanup policy

**Why** — Enforces REQ-MHK-001-08, REQ-MHK-001-10, REQ-MHK-001-11, REQ-MHK-001-12, REQ-MHK-001-16, and NF01-NF03.

**Anchor** — New cleanup directory; no existing source anchor.

**Change** — Define code-owned cleanup categories and approved roots. Before each mutation, re-resolve the path, verify containment, reject symbolic links and unapproved types, and compare current eligibility with the preview. Return a typed rejection reason instead of throwing away the batch.

**Proven by** — Negative safety tests reject unapproved paths, symlinks, changed items, missing items, and unconfirmed selections.

**Status** — complete.

### P3-2 — Implement cleanup command

**Why** — Delivers REQ-MHK-001-07 through REQ-MHK-001-12 and NF01-NF03.

**Anchor** — New cleanup command; no existing source anchor.

**Change** — Run a fresh cache scan and display selected findings with estimated size. Require explicit confirmation and process selections serially. Prefer recoverable removal and render completed/skipped/failed outcomes with the logical size moved to Trash. Cancellation and negative confirmation return without mutation.

**Proven by** — Integration tests snapshot a temporary fixture before and after preview/cancel/confirm flows and verify partial results.

**Status** — complete.

## 6. Phase 4 — verification and release preparation

This phase proves the safety boundary, performance requirement, and supported-Mac behaviour. 2 tasks.

### Task index

| # | Task | Kind | Artifact | Blocked by |
|---|---|---|---|---|
| P4-1 | Complete unit, integration, negative-safety, and CLI acceptance tests. | test | `Tests/MacHousekeeperTests/` | P1-2, P2-4, P3-2 |
| P4-2 | Run macOS manual/performance verification and write the developer release checklist. | process/docs | `docs/verification-checklist.md` | P4-1, X3 |

### P4-1 — Complete automated verification

**Why** — Proves every active PRD acceptance criterion and non-functional requirement before release.

**Anchor** — New test files; no existing source anchor.

**Change** — Add named tests from the approved technical design coverage table. Use temporary fixtures, injected command runners, and controlled providers. Ensure tests never delete real user data or require root.

**Proven by** — `swift test` passes and each active REQ row has a passing test.

**Status** — complete.

### P4-2 — Run manual and performance verification

**Why** — Proves platform-specific metadata, memory indicators, progress timing, and normal-user operation that cannot be fully simulated in unit tests.

**Anchor** — New document; no existing source anchor.

**Change** — Record supported macOS version, toolchain, fixture size, scan duration, first-progress time, permission behaviour, and offline observation. Document the reviewed cache allowlist and any indicator that remains unavailable.

**Proven by** — A reviewer can repeat the checklist on a supported Mac and confirm no real user data was mutated.

**Status** — in progress. The repeatable checklist and reviewed production cache catalog exist; target-machine manual execution remains outstanding.

## 7. Test plan — mapped to acceptance criteria

| REQ / criterion | Test | Level | Where it lives | Must fail before the change? |
|---|---|---|---|---|
| REQ-MHK-001-01 | `LargeFileScanTests.reportsThresholdMatchesWithMetadata` | unit/integration | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-02 | `CleanupScanTests.reportsEligibleItemsByCategory` | integration | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-03 | `ApplicationScanTests.reportsApplicationInventory` | integration/manual | `Tests/MacHousekeeperTests/` and checklist | yes |
| REQ-MHK-001-04 | `ApplicationScanTests.doesNotClassifyMissingEvidenceAsUnused` | unit | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-05 | `MemoryStatusTests.reportsTimestampedMemoryStatus` | integration/manual | `Tests/MacHousekeeperTests/` and checklist | yes |
| REQ-MHK-001-06 | `ScanSummaryTests.reportsCountsAndSizes` | unit | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-07 | `CleanupConfirmationTests.previewsSelectionBeforeMutation` | integration | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-08 | `CleanupExecutionTests.removesOnlyConfirmedEligibleItems` | integration | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-09 | `CleanupExecutionTests.reportsPerItemOutcomesAndActualSize` | integration | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-10 | `CleanupSafetyTests.doesNotMutateWithoutConfirmation` | negative safety | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-11 | `CleanupSafetyTests.continuesAfterItemLevelFailure` | negative safety | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-12 | `CleanupSafetyTests.reportsPartialCompletionAccurately` | negative safety | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-14 | `PermissionHandlingTests.continuesAfterDeniedLocation` | integration | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-15 | `ScanIntegrityTests.reportsUnknownInformationWithoutFabrication` | unit/integration | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-16 | `CleanupSafetyTests.rejectsItemsOutsideApprovedCategories` | negative safety | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-NF01 | `CleanupSafetyTests.doesNotMutateWithoutConfirmation` | negative safety | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-NF02 | `PrivilegeTests.runsWithoutRoot` | integration/manual | `Tests/MacHousekeeperTests/` and checklist | yes |
| REQ-MHK-001-NF03 | `CleanupSafetyTests.reportsAllItemOutcomes` | integration | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-NF04 | `OfflineOperationTests.opensNoNetworkConnection` | integration | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-NF05 | `CLIIntegrationTests.returnsFailureStatus` | integration | `Tests/MacHousekeeperTests/` | yes |
| REQ-MHK-001-NF06 | `ProgressTests.emitsProgressForLongScan` | performance | `Tests/MacHousekeeperTests/` | yes |

**Performance and non-functional tests** — A scan fixture that takes longer than two seconds must emit progress before completion. All cleanup tests must prove zero mutation without confirmation. Commands run as a normal user and do not open network connections.

**Manual verification** — The developer runs `docs/verification-checklist.md` on a supported Mac using temporary fixtures and records toolchain, OS, timing, permission, metadata, and memory observations.

## 8. Sequencing and deployment

| Step | Phase | Blocked by | Releases with |
|---|---|---|---|
| 1 | Phase 1 — package and CLI foundation | X1 | buildable command skeleton |
| 2 | Phase 2 — read-only providers | Step 1, X3 for platform checks | read-only scan and status commands |
| 3 | Phase 3 — safe cleanup | Step 2 | confirmed cache cleanup |
| 4 | Phase 4 — verification and release preparation | Step 3, X3 | reviewed MVP executable and checklist |

**Blast radius** — Local executable and user-selected cache items only; no service restart, schema change, network exposure, or shared deployment.

**Build** — Run `swift build`, then `swift test`, then the manual checklist. Build artifacts remain outside the repository through `.build/`.

**Rollback** — Remove or replace the executable. User cleanup is recoverable through macOS Trash where the operation succeeds; no persistent application data is written by the tool.

## 9. System map cards to update

None affected. There are no system-map cards yet; add them only through the approved project system-map process after implementation establishes current system facts.


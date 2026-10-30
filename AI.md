# AI.md

This is the entry point for AI-assisted work in the MacHousekeeper repository.

## Steering locations

| Location | Binding? | Purpose |
|---|---:|---|
| [.ai-steering/](.ai-steering/) | yes | Portable governance, architecture, security, and workflow rules. Keep these rules portable. |
| [.ai-mac-housekeeper-steering/](.ai-mac-housekeeper-steering/) | yes | MacHousekeeper-specific stack, safety rules, module ownership, and deliverable routing. |
| [docs/](docs/) | no | Product and engineering deliverables. |

`AI.md`, `CLAUDE.md`, both steering locations, and any future system-map location are governed files. Changes to binding steering files require explicit lead-architect approval. The lead architect approved the initial setup on 2026-10-15.

## Read by task

| If you are... | Read |
|---|---|
| about to make your first edit | [.ai-steering/governance.md](.ai-steering/governance.md) |
| starting a non-trivial change | [.ai-steering/architecture-principles.md](.ai-steering/architecture-principles.md) and [.ai-mac-housekeeper-steering/stack.md](.ai-mac-housekeeper-steering/stack.md) |
| touching filesystem cleanup, permissions, subprocesses, or user data | [.ai-steering/security.md](.ai-steering/security.md) and [.ai-mac-housekeeper-steering/security.md](.ai-mac-housekeeper-steering/security.md) |
| defining or revising a requirement | [.ai-steering/workflows/requirement-definition.md](.ai-steering/workflows/requirement-definition.md) and [.ai-mac-housekeeper-steering/workflows/requirement-definition.md](.ai-mac-housekeeper-steering/workflows/requirement-definition.md) |
| writing or revising a deliverable | [.ai-steering/workflows/design-document.md](.ai-steering/workflows/design-document.md) and [.ai-mac-housekeeper-steering/workflows/design-document.md](.ai-mac-housekeeper-steering/workflows/design-document.md) |
| investigating a defect | [.ai-steering/workflows/bug-resolution.md](.ai-steering/workflows/bug-resolution.md) |
| reviewing a pull request | [.ai-steering/workflows/pr-review.md](.ai-steering/workflows/pr-review.md) |

## Repository map

| Location | Purpose |
|---|---|
| `Sources/MacHousekeeper/` | Swift Package Manager executable source. |
| `Tests/MacHousekeeperTests/` | Unit and integration tests. |
| `docs/` | Product requirements, technical designs, implementation plans, and operational documentation. |
| `.ai-steering/` | Portable binding rules copied from the approved reference workspace. |
| `.ai-mac-housekeeper-steering/` | Project-specific binding rules. |

## Current project shape

MacHousekeeper is a macOS terminal utility for safe local storage inspection and cleanup. The repository now contains the approved PRD, technical design, implementation plan, and the initial Swift Package Manager executable foundation; feature implementation is in progress.

The MVP is expected to cover large-file discovery, supported regenerable-data discovery, explicitly confirmed cleanup, installed-application inventory, and memory-status reporting. Forced RAM purging, automatic application uninstallation, arbitrary file deletion, GUI support, network services, and telemetry are outside the current scope.

The product requirement baseline is [docs/PRD.md](docs/PRD.md). It is approved; implementation must continue to follow the approved design and plan.

## Where new work goes

| Adding... | Put it in |
|---|---|
| portable rule | `.ai-steering/` — approval required |
| MacHousekeeper-only rule | `.ai-mac-housekeeper-steering/` — approval required |
| product or engineering deliverable | `docs/` — follow the relevant workflow and template |
| application code | `Sources/MacHousekeeper/` |
| tests | `Tests/MacHousekeeperTests/` |
| current-system description | a future approved system-map location named here before cards are added |

Do not silently turn an implementation choice into a requirement. Requirements belong in the PRD; architecture and implementation choices belong in later design documents.

# MacHousekeeper requirement-definition routing

Read this file together with `.ai-steering/workflows/requirement-definition.md`.

## Project axes

Every requirement specification must state its position on these axes:

- supported macOS versions;
- normal-user versus elevated execution;
- terminal interaction mode;
- local/offline versus network behaviour;
- filesystem categories that may be inspected or mutated;
- recoverability and user confirmation for destructive actions.

## Filing

- Product and requirement deliverables belong under `docs/`.
- The current MVP intake draft is `docs/PRD.md`.
- A formally tracked requirement specification should move under a work-item-specific folder once the tracker identifier is confirmed.
- Do not mark a requirement specification Ready while its scope, safety rules, or approval gates remain open.

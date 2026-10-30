# MacHousekeeper design-document routing

Read this file together with `.ai-steering/workflows/design-document.md`.

## Deliverable locations

- Architecture approach documents: `docs/architecture/`.
- Technical design documents: `docs/technical-design/`.
- Implementation plans: `docs/implementation-plan/`.
- Requirement specifications and PRDs: `docs/` or a confirmed work-item subfolder under `docs/`.

## Project checklist

Every design for cleanup or scanning must define:

- supported macOS versions and required permissions;
- allowed and forbidden filesystem roots;
- symlink, race, permission-denied, and partial-failure behaviour;
- preview, confirmation, cancellation, and recovery behaviour;
- subprocess boundaries and exit-status handling;
- privacy, logging, and offline guarantees;
- tests that prove no unconfirmed mutation and no out-of-scope deletion.

There is no database schema or remote API in the current MVP. A future design must state that these surfaces remain absent unless a new approved requirement adds them.

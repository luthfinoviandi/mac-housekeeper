# MacHousekeeper security and data-safety rules

These rules are the project-specific form of the portable security baseline. They are hard constraints for storage inspection and cleanup.

## Filesystem safety

- Cleanup is dry-run or preview-only until the user explicitly confirms the operation.
- Cleanup targets come from an allowlist of approved, regenerable categories. Never derive an allowed cleanup root from arbitrary user input.
- Never clean system-critical paths, user documents, backups, iCloud data, browser profiles, developer data, or application bundles unless a later approved requirement adds the category.
- Revalidate the path, eligibility, type, and containment under the approved root immediately before mutation to reduce time-of-check/time-of-use risk.
- Do not follow symbolic links during discovery or cleanup unless a future approved design explicitly defines safe link handling.
- Prefer recoverable removal where macOS supports it. Permanent deletion requires a separate approved requirement.
- Do not request or require `sudo`, root privileges, or Full Disk Access for the MVP. Report denied locations and continue with accessible locations.
- A failed item must not prevent independent items from being processed, and the final result must distinguish completed, skipped, and failed items.

## Input and subprocess safety

- Parse CLI input as typed values with explicit bounds and allowlists.
- Never construct shell command strings from user input. Pass executable arguments as separate values to `Process`.
- Do not execute arbitrary commands supplied by the user.
- Treat paths, application metadata, filenames, and command output as untrusted data.

## Privacy and logging

- Operate offline for the MVP. Do not add telemetry or network transmission without a new approved requirement.
- Do not persist file inventories, application inventories, or memory observations unless a later approved requirement defines retention and protection.
- Local terminal output may show the path needed for the user to understand a finding, but logs must not expose secrets or unrelated file contents.
- Error output must not include shell commands containing secrets, uncontrolled stack traces, or data read from user files.

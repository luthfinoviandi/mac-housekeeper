# MacHousekeeper stack and conventions

## Product target

- macOS-only terminal executable for the MVP.
- Local/offline operation.
- Normal user privileges; root execution is not required or assumed.
- Swift 6.x with Swift Package Manager.
- Use Apple platform APIs before adding third-party dependencies.

## Platform boundaries

- Use Foundation for filesystem, process, URL, and system-information work.
- Use AppKit only where macOS application discovery or application lifecycle information requires it.
- Treat command-line tools invoked through `Process` as external dependencies: validate arguments, capture exit status, and report unavailable tools.
- Keep scanning and cleanup separate. A scan is read-only; cleanup is an explicit mutation.

## Source layout

- Executable code belongs under `Sources/MacHousekeeper/`.
- Tests belong under `Tests/MacHousekeeperTests/`.
- Keep the first implementation small: avoid service frameworks, persistence, background daemons, and abstractions without a current caller.
- Any non-trivial branch, traversal, classification, or cleanup rule gets a focused test.

## Product language

Use “memory status” or “memory pressure report”, not “RAM refresh”. The product must not promise that it can directly free or refresh macOS memory.

Use “candidate unused application” when usage evidence is incomplete. Do not state that an application is unused without evidence.

# MacHousekeeper MVP Verification Checklist

This checklist is for a supported macOS machine. Use only disposable fixtures and a normal user account. Do not point cleanup at real personal, browser, developer, backup, iCloud, or application data.

## Current implementation state

- [x] `swift build` succeeds.
- [x] `swift test` passes the checked-in fixture suite.
- [x] The first read-only SwiftUI slice exists as `MacHousekeeperCore` plus `MacHousekeeperApp`; it shows cache summary, memory status, warnings, and loading/error/empty states without cleanup controls.
- [x] A narrow, code-owned production cache catalog is configured. This machine exposes the reviewed Help cache root.
- [ ] Manual macOS, permission, performance, and real Trash verification is complete.

Packaging limitation: Swift Package Manager builds the `MacHousekeeperApp` executable target, but this slice does not yet produce a signed `.app` bundle, entitlements, installer, or distribution artifact. Run it from the package during development.

The catalog currently includes only these user-owned macOS service caches: `com.apple.helpd`, `com.apple.iconservices`, and `com.apple.quicklook.ThumbnailsAgent` under `~/Library/Caches`. Browser, developer, backup, cloud-sync, and application data are excluded.

## Environment record

Record these values before running the checks:

```text
Date/time (Asia/Jakarta): 2026-10-16
macOS version:            26.5.2
Architecture:             arm64
Swift version:             6.3.3
User is root:              no (UID 501)
Repository revision:       uncommitted working tree
```

The MVP must run as a normal user. Do not grant `sudo` or Full Disk Access to make a fixture pass.

## Automated baseline

From the repository root:

```text
swift build
swift test
```

Expected result: both commands complete successfully and the test suite reports zero failures.

Observed on 2026-10-17: `swift test` passed 40 tests with zero failures.

## Read-only command checks

Create a temporary directory containing a small file and a larger file. Keep the path outside the repository and remove it after verification.

```text
mac-housekeeper scan large-files --root <fixture> --min-size 1
mac-housekeeper scan caches
mac-housekeeper scan apps
mac-housekeeper memory
```

Verify:

- Large-file output includes the threshold match, path, size, and summary.
- Cache output reports unavailable reviewed roots rather than inferring approval from arbitrary paths.
- Application output preserves unknown usage evidence instead of calling an application unused.
- Memory output includes an observation timestamp and states unavailable indicators explicitly.
- No command creates, modifies, or deletes fixture contents.

Observed on 2026-10-16:

- `scan large-files` against `Package.swift` reported one 498-byte finding and exited successfully.
- `scan caches` found eight findings under the reviewed Help cache root and exited successfully.
- `scan apps` completed with 37 application findings and reported symlink traversal warnings; usage evidence was explicitly unknown.
- `clean caches` displayed the preview; entering `none` canceled cleanup and no files were changed.
- `memory` reported a timestamped observation, 8.59 GB physical memory, 1.36 GB available memory, and unavailable swap indicators.
- A missing large-file root produced a warning and non-zero exit status.
- The bounded platform-command timeout regression passed; the full default application scan completed after the timeout fix.

## Cleanup safety checks

These checks require an approved catalog root to exist on the test machine. Until one is available, record the check as blocked rather than supplying an arbitrary path.

With a disposable approved fixture and an injected or controlled test remover, verify:

- Preview lists only eligible findings and estimated sizes.
- `none`, malformed selection, and negative confirmation leave the fixture unchanged.
- Confirmation revalidates path, eligibility, type, containment, symbolic-link state, and size.
- A missing, changed, symlinked, or unapproved item is skipped.
- One failed item does not suppress later outcomes.
- Every selected item has exactly one terminal outcome.
- Removal uses macOS Trash and never permanent deletion.
- Output distinguishes bytes moved to Trash from actual disk-space reclamation.

## Permission and interruption checks

Using disposable directories and a normal user:

- Include one inaccessible or missing location beside one accessible location.
- Confirm the accessible location is still scanned and the limitation is reported.
- Interrupt a long read-only scan and record whether the process exits cleanly.
- Interrupt cleanup only with disposable data and record any completed or pending item outcomes.

If interruption cannot produce a final outcome report, document that limitation before release.

## Performance and offline checks

Use a bounded disposable fixture large enough to run longer than two seconds on the target Mac, or an injected slow provider for deterministic testing. Record:

```text
Fixture item count:
Fixture logical size:
Scan duration:
Time to first progress event:
Progress events before completion:
```

Verify progress is emitted before completion and that the scan remains bounded by the selected fixture.

During all commands, verify no network connection or telemetry process is created. The MVP must operate offline.

## Release decision

- [x] All automated tests pass.
- [x] A reviewed, narrow cache catalog is documented and wired into scan and cleanup.
- [ ] Manual platform checks pass on a supported Mac.
- [x] No real user data was mutated.
- [x] Known limitations and unavailable indicators are recorded.

Do not mark the MVP release-ready while approved roots are unavailable for verification, or while manual Trash and interruption behavior remain unresolved.

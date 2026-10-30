import Foundation
import XCTest
@testable import MacHousekeeper
@testable import MacHousekeeperCore

private struct FixedApplicationUsageProvider: ApplicationUsageEvidenceProvider {
    let state: EvidenceState

    /// Returns the fixture evidence without invoking a platform metadata command.
    func evidence(for applicationURL: URL) -> EvidenceState {
        state
    }
}

final class ScanningTests: XCTestCase {
    /// Creates an isolated fixture directory and removes it after the test body completes.
    private func withTemporaryDirectory(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacHousekeeperTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory)
    }

    /// Creates a minimal application bundle fixture with the requested Info.plist metadata.
    private func createApplication(
        at root: URL,
        name: String,
        displayName: String,
        identifier: String,
        dataSize: Int
    ) throws -> URL {
        let application = root.appendingPathComponent("\(name).app")
        let contents = application.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let info: [String: String] = [
            "CFBundleDisplayName": displayName,
            "CFBundleIdentifier": identifier,
            "CFBundleName": name
        ]
        let plist = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try plist.write(to: contents.appendingPathComponent("Info.plist"))
        XCTAssertTrue(FileManager.default.createFile(
            atPath: contents.appendingPathComponent("data").path,
            contents: Data(repeating: 1, count: dataSize)
        ))
        return application
    }

    /// Verifies threshold filtering, metadata capture, ordering, and read-only classification.
    func testFileScannerReportsThresholdMatchesWithMetadata() throws {
        try withTemporaryDirectory { directory in
            let small = directory.appendingPathComponent("small.bin")
            let large = directory.appendingPathComponent("large.bin")
            XCTAssertTrue(FileManager.default.createFile(atPath: small.path, contents: Data(repeating: 1, count: 4)))
            XCTAssertTrue(FileManager.default.createFile(atPath: large.path, contents: Data(repeating: 1, count: 12)))

            let result = FileScanner(root: directory, minimumSize: 10).scan { _ in }

            XCTAssertEqual(result.findings.count, 1)
            XCTAssertTrue(result.findings.first?.path.path.hasSuffix("/large.bin") == true)
            XCTAssertEqual(result.findings.first?.size, 12)
            XCTAssertNotNil(result.findings.first?.modificationDate)
            XCTAssertEqual(result.findings.first?.eligibility, .readOnly)
            XCTAssertEqual(result.summary.totalBytes, 12)
        }
    }

    /// Verifies symbolic links are skipped and do not cause the target to be scanned twice.
    func testFileScannerSkipsSymbolicLinks() throws {
        try withTemporaryDirectory { directory in
            let target = directory.appendingPathComponent("target.bin")
            let link = directory.appendingPathComponent("link.bin")
            XCTAssertTrue(FileManager.default.createFile(atPath: target.path, contents: Data(repeating: 1, count: 12)))
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)

            let result = FileScanner(root: directory, minimumSize: 10).scan { _ in }

            XCTAssertEqual(result.findings.map(\.path.lastPathComponent), ["target.bin"])
            XCTAssertTrue(result.warnings.contains { $0.location?.standardizedFileURL == link.standardizedFileURL })
        }
    }

    /// Verifies progress callbacks are emitted for scanned items when the interval is immediate.
    func testFileScannerEmitsProgress() throws {
        try withTemporaryDirectory { directory in
            let file = directory.appendingPathComponent("file.bin")
            XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: Data(repeating: 1, count: 8)))
            var events: [ScanProgress] = []

            _ = FileScanner(root: directory, minimumSize: 1, progressInterval: 0).scan {
                events.append($0)
            }

            XCTAssertGreaterThanOrEqual(events.count, 3)
            XCTAssertEqual(events.first?.providerName, "large-files")
            XCTAssertEqual(events.last?.findingCount, 1)
        }
    }

    /// Verifies eligible and scan-only cache locations retain their policy decision and size.
    func testCacheScannerReportsPolicyAndEstimatedSize() throws {
        try withTemporaryDirectory { directory in
            let eligibleRoot = directory.appendingPathComponent("reviewed")
            let unknownRoot = directory.appendingPathComponent("unknown")
            try FileManager.default.createDirectory(at: eligibleRoot, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: unknownRoot, withIntermediateDirectories: true)
            let eligibleItem = eligibleRoot.appendingPathComponent("eligible-item")
            let unknownItem = unknownRoot.appendingPathComponent("unknown-item")
            try FileManager.default.createDirectory(at: eligibleItem, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: unknownItem, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(
                atPath: eligibleItem.appendingPathComponent("data").path,
                contents: Data(repeating: 1, count: 16)
            ))
            XCTAssertTrue(FileManager.default.createFile(
                atPath: unknownItem.appendingPathComponent("data").path,
                contents: Data(repeating: 1, count: 8)
            ))

            let scanner = CacheScanner(
                locations: [
                    CacheLocation(name: "Reviewed", root: eligibleRoot, eligibility: .eligible),
                    CacheLocation(name: "Unknown", root: unknownRoot, eligibility: .readOnly)
                ]
            )
            let result = scanner.scan { _ in }

            XCTAssertEqual(result.findings.count, 2)
            XCTAssertEqual(result.findings.map(\.size), [16, 8])
            XCTAssertEqual(result.findings.map(\.eligibility), [.eligible, .readOnly])
            XCTAssertEqual(result.findings.last?.reason, "Location is not approved for cleanup.")
            XCTAssertEqual(result.summary.eligibleBytes, 16)
        }
    }

    /// Verifies one inaccessible cache location does not prevent independent locations from scanning.
    func testCacheScannerContinuesAfterMissingLocation() throws {
        try withTemporaryDirectory { directory in
            let missingRoot = directory.appendingPathComponent("missing")
            let validRoot = directory.appendingPathComponent("valid")
            let validItem = validRoot.appendingPathComponent("item")
            try FileManager.default.createDirectory(at: validItem, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(
                atPath: validItem.appendingPathComponent("data").path,
                contents: Data(repeating: 1, count: 6)
            ))

            let result = CacheScanner(
                locations: [
                    CacheLocation(name: "Missing", root: missingRoot, eligibility: .readOnly),
                    CacheLocation(name: "Valid", root: validRoot, eligibility: .eligible)
                ]
            ).scan { _ in }

            XCTAssertEqual(result.findings.count, 1)
            XCTAssertEqual(result.findings.first?.path.lastPathComponent, "item")
            XCTAssertTrue(result.warnings.contains { $0.location == missingRoot })
        }
    }

    /// Verifies the production catalog returns only existing, non-symlinked reviewed roots.
    func testReviewedCacheCatalogExcludesMissingAndSymlinkedRoots() throws {
        try withTemporaryDirectory { home in
            let cacheRoot = home.appendingPathComponent("Library/Caches")
            let approved = cacheRoot.appendingPathComponent("com.apple.helpd")
            let symlinkTarget = home.appendingPathComponent("real-cache")
            let symlinked = cacheRoot.appendingPathComponent("com.apple.iconservices")
            try FileManager.default.createDirectory(at: approved, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: symlinkTarget, withIntermediateDirectories: true)
            try FileManager.default.createSymbolicLink(at: symlinked, withDestinationURL: symlinkTarget)

            let locations = ReviewedCacheCatalog.locations(homeDirectory: home)

            XCTAssertEqual(locations.map(\.name), ["macOS help cache"])
            XCTAssertEqual(locations.first?.eligibility, .eligible)
        }
    }

    /// Verifies a symlinked cache root is rejected before its target is traversed.
    func testCacheScannerSkipsSymbolicLinkRoot() throws {
        try withTemporaryDirectory { directory in
            let target = directory.appendingPathComponent("target")
            let root = directory.appendingPathComponent("linked-root")
            let item = target.appendingPathComponent("item")
            try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: item.path, contents: Data(repeating: 1, count: 4)))
            try FileManager.default.createSymbolicLink(at: root, withDestinationURL: target)

            let result = CacheScanner(
                locations: [CacheLocation(name: "Linked", root: root, eligibility: .eligible)]
            ).scan { _ in }

            XCTAssertTrue(result.findings.isEmpty)
            XCTAssertTrue(result.warnings.contains {
                $0.location?.path == root.path && $0.message == "Symbolic links are not scanned."
            })
        }
    }

    /// Verifies a denied cache location is reported while an accessible location still scans.
    func testCacheScannerContinuesAfterPermissionDeniedLocation() throws {
        try withTemporaryDirectory { directory in
            let deniedRoot = directory.appendingPathComponent("denied")
            let validRoot = directory.appendingPathComponent("valid")
            let validItem = validRoot.appendingPathComponent("item")
            try FileManager.default.createDirectory(at: deniedRoot, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: validItem, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(
                atPath: validItem.appendingPathComponent("data").path,
                contents: Data(repeating: 1, count: 6)
            ))
            try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: deniedRoot.path)
            defer { try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: deniedRoot.path) }

            let result = CacheScanner(
                locations: [
                    CacheLocation(name: "Denied", root: deniedRoot, eligibility: .readOnly),
                    CacheLocation(name: "Valid", root: validRoot, eligibility: .eligible)
                ]
            ).scan { _ in }

            XCTAssertEqual(result.findings.count, 1)
            XCTAssertEqual(result.findings.first?.path.lastPathComponent, "item")
            XCTAssertTrue(result.warnings.contains { $0.location == deniedRoot || $0.location?.path == deniedRoot.path })
        }
    }

    /// Verifies application metadata, installed size, and known usage evidence are reported.
    func testApplicationScannerReportsInventory() throws {
        try withTemporaryDirectory { directory in
            let applicationsRoot = directory.appendingPathComponent("Applications")
            try FileManager.default.createDirectory(at: applicationsRoot, withIntermediateDirectories: true)
            let application = try createApplication(
                at: applicationsRoot,
                name: "Example",
                displayName: "Example App",
                identifier: "com.example.app",
                dataSize: 18
            )

            let result = ApplicationScanner(
                roots: [applicationsRoot],
                usageProvider: FixedApplicationUsageProvider(state: .observed("Last used: fixture"))
            ).scan { _ in }

            XCTAssertEqual(result.findings.count, 1)
            XCTAssertEqual(result.findings.first?.path.lastPathComponent, application.lastPathComponent)
            XCTAssertEqual(result.findings.first?.displayName, "Example App")
            XCTAssertEqual(result.findings.first?.identifier, "com.example.app")
            XCTAssertGreaterThanOrEqual(result.findings.first?.size ?? 0, 18)
            XCTAssertEqual(result.findings.first?.evidence, .observed("Last used: fixture"))
            XCTAssertEqual(result.findings.first?.eligibility, .readOnly)
        }
    }

    /// Verifies missing usage evidence remains unknown instead of being labelled unused.
    func testApplicationScannerPreservesUnknownUsageEvidence() throws {
        try withTemporaryDirectory { directory in
            _ = try createApplication(
                at: directory,
                name: "UnknownUsage",
                displayName: "Unknown Usage",
                identifier: "com.example.unknown",
                dataSize: 4
            )

            let result = ApplicationScanner(
                roots: [directory],
                usageProvider: FixedApplicationUsageProvider(state: .unknown("Usage metadata is unavailable."))
            ).scan { _ in }

            XCTAssertEqual(result.findings.first?.evidence, .unknown("Usage metadata is unavailable."))
            XCTAssertFalse(result.findings.first?.reason?.localizedCaseInsensitiveContains("unused") == true)
        }
    }
}

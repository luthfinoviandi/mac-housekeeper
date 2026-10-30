import Foundation
import XCTest
@testable import MacHousekeeper
@testable import MacHousekeeperCore

final class CleanupPolicyTests: XCTestCase {
    /// Creates an isolated fixture directory and removes it after the test body completes.
    private func withTemporaryDirectory(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacHousekeeperTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory)
    }

    /// Creates a cache finding with only the fields relevant to policy validation.
    private func finding(
        path: URL,
        size: UInt64,
        category: FindingCategory = .cache,
        eligibility: FindingEligibility = .eligible,
        modificationDate: Date? = nil
    ) -> Finding {
        Finding(
            id: "cache-1",
            category: category,
            path: path,
            size: size,
            modificationDate: modificationDate,
            eligibility: eligibility,
            evidence: nil,
            reason: nil
        )
    }

    /// Verifies an unchanged eligible descendant passes and returns a canonical target.
    func testPolicyAcceptsUnchangedEligibleItem() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let item = root.appendingPathComponent("item")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: item.path, contents: Data(repeating: 1, count: 4)))

            let result = CleanupPolicy(
                approvedCategories: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)]
            ).validate(finding(path: item, size: 4))

            guard case let .success(target) = result else {
                return XCTFail("Expected the unchanged eligible item to pass validation.")
            }
            XCTAssertEqual(target.findingID, "cache-1")
            XCTAssertEqual(target.path.lastPathComponent, "item")
            XCTAssertEqual(target.currentSize, 4)
        }
    }

    /// Verifies findings outside reviewed roots are rejected before any mutation can occur.
    func testPolicyRejectsUnapprovedPath() throws {
        try withTemporaryDirectory { directory in
            let approvedRoot = directory.appendingPathComponent("reviewed")
            let outside = directory.appendingPathComponent("outside")
            try FileManager.default.createDirectory(at: approvedRoot, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: outside.path, contents: Data(repeating: 1, count: 4)))

            let result = CleanupPolicy(
                approvedCategories: [CacheLocation(name: "Reviewed", root: approvedRoot, eligibility: .eligible)]
            ).validate(finding(path: outside, size: 4))

            XCTAssertEqual(result, .failure(.unapprovedPath))
        }
    }

    /// Verifies symlink targets are rejected even when the link path is lexically allowlisted.
    func testPolicyRejectsSymbolicLink() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let target = directory.appendingPathComponent("target")
            let link = root.appendingPathComponent("link")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: target.path, contents: Data(repeating: 1, count: 4)))
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)

            let result = CleanupPolicy(
                approvedCategories: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)]
            ).validate(finding(path: link, size: 4))

            XCTAssertEqual(result, .failure(.symbolicLink))
        }
    }

    /// Verifies a changed item is skipped rather than treated as the previewed target.
    func testPolicyRejectsChangedItem() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let item = root.appendingPathComponent("item")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: item.path, contents: Data(repeating: 1, count: 8)))

            let result = CleanupPolicy(
                approvedCategories: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)]
            ).validate(finding(path: item, size: 4))

            XCTAssertEqual(result, .failure(.changedSize(expected: 4, actual: 8)))
        }
    }

    /// Verifies a same-sized replacement with changed metadata is rejected before mutation.
    func testPolicyRejectsChangedModificationDate() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let item = root.appendingPathComponent("item")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: item.path, contents: Data(repeating: 1, count: 4)))
            try FileManager.default.setAttributes(
                [.modificationDate: Date(timeIntervalSince1970: 1)],
                ofItemAtPath: item.path
            )

            let result = CleanupPolicy(
                approvedCategories: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)]
            ).validate(finding(path: item, size: 4, modificationDate: Date(timeIntervalSince1970: 2)))

            XCTAssertEqual(result, .failure(.changedModificationDate))
        }
    }

    /// Verifies a previewed item removed before confirmation is rejected safely.
    func testPolicyRejectsMissingItem() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let item = root.appendingPathComponent("missing")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

            let result = CleanupPolicy(
                approvedCategories: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)]
            ).validate(finding(path: item, size: 4))

            XCTAssertEqual(result, .failure(.missing))
        }
    }

    /// Verifies read-only and non-cache findings cannot cross the cleanup boundary.
    func testPolicyRejectsIneligibleAndUnsupportedFindings() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let item = root.appendingPathComponent("item")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: item.path, contents: Data(repeating: 1, count: 4)))
            let policy = CleanupPolicy(
                approvedCategories: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)]
            )

            XCTAssertEqual(policy.validate(finding(path: item, size: 4, eligibility: .readOnly)), .failure(.notEligible))
            XCTAssertEqual(policy.validate(finding(path: item, size: 4, category: .largeFile)), .failure(.unsupportedCategory))
        }
    }
}

import Foundation
import XCTest
@testable import MacHousekeeper
@testable import MacHousekeeperCore

final class CleanupExecutionTests: XCTestCase {
    /// Records recoverable-removal requests and optionally fails selected paths.
    private final class RecordingRemover: RecoverableRemover {
        private(set) var movedPaths: [URL] = []
        let failingPaths: Set<URL>

        /// Creates a remover double for mutation and partial-failure assertions.
        /// - Parameter failingPaths: Paths that should report a removal failure.
        init(failingPaths: Set<URL> = []) {
            self.failingPaths = failingPaths
        }

        /// Records a path and optionally throws to simulate the Trash operation failing.
        /// - Parameter path: Path requested by the executor.
        /// - Throws: A synthetic error for configured failing paths.
        func moveToTrash(_ path: URL) throws {
            movedPaths.append(path)
            if failingPaths.contains(path) {
                throw TestError.removalFailed
            }
        }
    }

    /// Defines the one failure needed by the recording remover.
    private enum TestError: Error {
        case removalFailed
    }

    /// Creates an isolated fixture directory and removes it after the test body completes.
    private func withTemporaryDirectory(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacHousekeeperCleanupTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory)
    }

    /// Creates a cache finding with the fields required by cleanup validation.
    private func finding(path: URL, size: UInt64, id: String = "cache-1") -> Finding {
        Finding(
            id: id,
            category: .cache,
            path: path,
            size: size,
            modificationDate: nil,
            eligibility: .eligible,
            evidence: nil,
            reason: nil
        )
    }

    /// Verifies that an unconfirmed executor produces no removal request.
    func testExecutorDoesNotMutateWithoutConfirmation() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let item = root.appendingPathComponent("item")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: item.path, contents: Data(repeating: 1, count: 4)))
            let remover = RecordingRemover()
            let executor = CleanupExecutor(
                policy: CleanupPolicy(approvedCategories: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)]),
                remover: remover
            )

            let outcomes = executor.execute(findings: [finding(path: item, size: 4)], confirmed: false)

            XCTAssertEqual(remover.movedPaths, [])
            XCTAssertEqual(outcomes, [CleanupOutcome(
                findingID: "cache-1",
                result: .skipped,
                reclaimedBytes: 0,
                reason: "Cleanup was not confirmed."
            )])
        }
    }

    /// Verifies that only validated confirmed findings are sent to the recoverable remover.
    func testExecutorMovesConfirmedEligibleItems() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let first = root.appendingPathComponent("first")
            let second = root.appendingPathComponent("second")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: first.path, contents: Data(repeating: 1, count: 4)))
            XCTAssertTrue(FileManager.default.createFile(atPath: second.path, contents: Data(repeating: 1, count: 8)))
            let remover = RecordingRemover()
            let executor = CleanupExecutor(
                policy: CleanupPolicy(approvedCategories: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)]),
                remover: remover
            )

            let outcomes = executor.execute(
                findings: [finding(path: first, size: 4), finding(path: second, size: 8, id: "cache-2")],
                confirmed: true
            )

            XCTAssertEqual(remover.movedPaths, [first, second])
            XCTAssertEqual(outcomes.map(\.result), [.completed, .completed])
            XCTAssertEqual(outcomes.map(\.reclaimedBytes), [4, 8])
        }
    }

    /// Verifies that one removal failure does not suppress later item outcomes.
    func testExecutorReportsPartialRemovalFailure() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let first = root.appendingPathComponent("first")
            let second = root.appendingPathComponent("second")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: first.path, contents: Data(repeating: 1, count: 4)))
            XCTAssertTrue(FileManager.default.createFile(atPath: second.path, contents: Data(repeating: 1, count: 8)))
            let remover = RecordingRemover(failingPaths: [first])
            let executor = CleanupExecutor(
                policy: CleanupPolicy(approvedCategories: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)]),
                remover: remover
            )

            let outcomes = executor.execute(
                findings: [finding(path: first, size: 4), finding(path: second, size: 8, id: "cache-2")],
                confirmed: true
            )

            XCTAssertEqual(remover.movedPaths, [first, second])
            XCTAssertEqual(outcomes.map(\.result), [.failed, .completed])
            XCTAssertEqual(outcomes[0].reclaimedBytes, 0)
            XCTAssertEqual(outcomes[1].reclaimedBytes, 8)
        }
    }

    /// Verifies that a negative confirmation leaves the fixture untouched and unrequested.
    func testCleanCommandDoesNotMutateAfterNegativeConfirmation() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let item = root.appendingPathComponent("item")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: item.path, contents: Data(repeating: 1, count: 4)))
            let remover = RecordingRemover()
            var inputs = ["all", "no"]
            let result = CleanCommand(
                cacheLocations: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)],
                input: { inputs.removeFirst() },
                output: { _ in },
                remover: remover
            ).run()

            XCTAssertFalse(result.confirmed)
            XCTAssertEqual(remover.movedPaths, [])
            XCTAssertTrue(FileManager.default.fileExists(atPath: item.path))
            XCTAssertEqual(result.outcomes.map(\.result), [.skipped])
        }
    }

    /// Verifies the preview is rendered before selection and confirmation are requested.
    func testCleanCommandPreviewsBeforeConfirmation() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let item = root.appendingPathComponent("item")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: item.path, contents: Data(repeating: 1, count: 4)))
            let remover = RecordingRemover()
            var inputs = ["none"]
            var output: [String] = []

            _ = CleanCommand(
                cacheLocations: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)],
                input: { inputs.removeFirst() },
                output: { output.append($0) },
                remover: remover
            ).run()

            let rendered = output.joined(separator: "\n")
            guard let preview = rendered.range(of: "Cleanup preview"),
                  let selection = rendered.range(of: "Select item numbers") else {
                return XCTFail("Expected the preview and selection prompt.")
            }
            XCTAssertLessThan(preview.lowerBound, selection.lowerBound)
            XCTAssertTrue(rendered.contains("Estimated reclaimable size:"))
            XCTAssertEqual(remover.movedPaths, [])
        }
    }

    /// Verifies that explicit confirmation sends only the selected item to recovery.
    func testCleanCommandMovesExplicitlySelectedItem() throws {
        try withTemporaryDirectory { directory in
            let root = directory.appendingPathComponent("reviewed")
            let first = root.appendingPathComponent("first")
            let second = root.appendingPathComponent("second")
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            XCTAssertTrue(FileManager.default.createFile(atPath: first.path, contents: Data(repeating: 1, count: 4)))
            XCTAssertTrue(FileManager.default.createFile(atPath: second.path, contents: Data(repeating: 1, count: 8)))
            let remover = RecordingRemover()
            var inputs = ["1", "yes"]
            let result = CleanCommand(
                cacheLocations: [CacheLocation(name: "Reviewed", root: root, eligibility: .eligible)],
                input: { inputs.removeFirst() },
                output: { _ in },
                remover: remover
            ).run()

            XCTAssertTrue(result.confirmed)
            XCTAssertEqual(result.selectedFindings.count, 1)
            XCTAssertEqual(remover.movedPaths, [second])
            XCTAssertEqual(result.outcomes.map(\.result), [.completed])
            XCTAssertEqual(result.outcomes[0].reclaimedBytes, 8)
        }
    }

    /// Verifies mixed cleanup outcomes are rendered as partial and do not claim physical reclamation.
    func testCleanupOutputMarksPartialAndLogicalTrashSize() {
        let output = CLIOutput.render([
            CleanupOutcome(findingID: "cache-1", result: .completed, reclaimedBytes: 4, reason: nil),
            CleanupOutcome(findingID: "cache-2", result: .failed, reclaimedBytes: 0, reason: "Recoverable removal failed.")
        ])

        XCTAssertTrue(output.contains("Cleanup result — partial"))
        XCTAssertTrue(output.contains("Logical size moved to Trash:"))
        XCTAssertFalse(output.contains("Actually reclaimed:"))
    }
}

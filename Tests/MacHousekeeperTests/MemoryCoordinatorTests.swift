import Foundation
import XCTest
@testable import MacHousekeeper
@testable import MacHousekeeperCore

private struct FixedSystemCommandRunner: SystemCommandRunner {
    let outputs: [String: SystemCommandOutput]

    /// Returns the fixture output selected by the absolute executable path.
    func run(executable: URL, arguments: [String]) -> SystemCommandOutput? {
        outputs[executable.path]
    }
}

final class MemoryCoordinatorTests: XCTestCase {
    /// Creates an isolated fixture directory and removes it after the test body completes.
    private func withTemporaryDirectory(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacHousekeeperTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory)
    }

    /// Verifies memory and swap parsers produce a timestamped status from supported output.
    func testMemoryReporterReportsTimestampedStatus() {
        let runner = FixedSystemCommandRunner(outputs: [
            "/usr/bin/vm_stat": SystemCommandOutput(
                status: 0,
                standardOutput: "page size of 16384 bytes\nPages free: 10.\nPages inactive: 20.\nPages speculative: 2.\n"
            ),
            "/usr/sbin/sysctl": SystemCommandOutput(
                status: 0,
                standardOutput: "total = 4.00G  used = 512.00M  free = 3.50G  used = 12.5M"
            )
        ])
        let before = Date()

        let status = MemoryReporter(commandRunner: runner).report()

        XCTAssertGreaterThanOrEqual(status.observedAt, before)
        XCTAssertGreaterThan(status.physicalMemoryBytes ?? 0, 0)
        XCTAssertEqual(status.availableMemoryBytes, 32 * 16_384)
        XCTAssertEqual(status.swapTotalBytes, 4 * 1_073_741_824)
        XCTAssertEqual(status.swapUsedBytes, 512 * 1_048_576)
        XCTAssertTrue(status.limitations.isEmpty)
    }

    /// Verifies unavailable external indicators remain explicit limitations instead of fabricated values.
    func testMemoryReporterReportsUnavailableIndicators() {
        let status = MemoryReporter(commandRunner: FixedSystemCommandRunner(outputs: [:])).report()

        XCTAssertNil(status.availableMemoryBytes)
        XCTAssertNil(status.swapTotalBytes)
        XCTAssertNil(status.swapUsedBytes)
        XCTAssertEqual(status.limitations.count, 2)
    }

    /// Verifies fixed platform commands are terminated instead of hanging indefinitely.
    func testProcessSystemCommandRunnerTimesOut() {
        let output = ProcessSystemCommandRunner(timeout: 0.01).run(
            executable: URL(fileURLWithPath: "/bin/sleep"),
            arguments: ["1"]
        )

        XCTAssertNil(output)
    }

    /// Verifies the coordinator selects the large-file provider and forwards its result.
    func testScanCoordinatorSelectsLargeFileProvider() throws {
        try withTemporaryDirectory { directory in
            let file = directory.appendingPathComponent("large.bin")
            XCTAssertTrue(FileManager.default.createFile(atPath: file.path, contents: Data(repeating: 1, count: 8)))
            var progressEvents: [ScanProgress] = []
            let request = ScanRequest.scanLargeFiles(root: directory, minimumSize: 1)

            let result = ScanCoordinator(progressInterval: 0).scan(request: request) {
                progressEvents.append($0)
            }

            XCTAssertEqual(result.findings.first?.category, .largeFile)
            XCTAssertEqual(result.findings.first?.size, 8)
            XCTAssertGreaterThanOrEqual(progressEvents.count, 2)
        }
    }

    /// Verifies cache scanning reports its empty reviewed policy explicitly.
    func testScanCoordinatorReportsMissingCachePolicy() throws {
        let result = ScanCoordinator().scan(request: .scanCaches) { _ in }

        XCTAssertEqual(result.findings, [])
        XCTAssertEqual(result.warnings.last?.message, "No reviewed cache locations are available.")
    }
}

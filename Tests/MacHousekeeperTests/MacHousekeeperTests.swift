import XCTest
@testable import MacHousekeeper
@testable import MacHousekeeperCore

final class MacHousekeeperTests: XCTestCase {
    /// Verifies terminal scan commands map to the core request without leaking CLI types into Core.
    func testCLICommandMapsToCoreScanRequest() {
        let root = URL(fileURLWithPath: "/tmp/fixture")

        XCTAssertEqual(
            CLICommand.scanLargeFiles(root: root, minimumSize: 42).scanRequest,
            .scanLargeFiles(root: root, minimumSize: 42)
        )
        XCTAssertEqual(CLICommand.scanCaches.scanRequest, .scanCaches)
        XCTAssertEqual(CLICommand.scanApplications.scanRequest, .scanApplications)
        XCTAssertNil(CLICommand.memory.scanRequest)
        XCTAssertNil(CLICommand.cleanCaches.scanRequest)
    }

    func testApplicationName() {
        XCTAssertEqual(MacHousekeeper.appName, "MacHousekeeper")
    }

    func testNoArgumentsShowsHelp() throws {
        XCTAssertEqual(try CLIParser().parse([]), .help)
    }

    func testParsesLargeFileOptions() throws {
        let command = try CLIParser().parse([
            "scan", "large-files", "--root", "Documents", "--min-size", "1024"
        ])

        XCTAssertEqual(
            command,
            .scanLargeFiles(
                root: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                    .appendingPathComponent("Documents"),
                minimumSize: 1024
            )
        )
    }

    func testRejectsZeroMinimumSize() {
        XCTAssertThrowsError(try CLIParser().parse(["scan", "large-files", "--min-size", "0"])) { error in
            XCTAssertEqual(
                error as? CLIParseError,
                .invalidValue(option: "--min-size", value: "0")
            )
        }
    }

    func testRejectsUnknownCommand() {
        XCTAssertThrowsError(try CLIParser().parse(["remove-everything"])) { error in
            XCTAssertEqual(error as? CLIParseError, .unknownCommand("remove-everything"))
        }
    }

    func testHelpListsMVPCommands() {
        XCTAssertTrue(CLIOutput.help.contains("scan large-files"))
        XCTAssertTrue(CLIOutput.help.contains("clean caches"))
    }

    /// Verifies summary counts and byte totals do not depend on filesystem enumeration order.
    func testScanSummaryAggregatesFindingsRegardlessOfOrder() {
        let first = Finding(
            id: "large-1",
            category: .largeFile,
            path: URL(fileURLWithPath: "/tmp/large.bin"),
            size: 10,
            modificationDate: nil,
            eligibility: .readOnly,
            evidence: nil,
            reason: nil
        )
        let second = Finding(
            id: "cache-1",
            category: .cache,
            path: URL(fileURLWithPath: "/tmp/cache"),
            size: 20,
            modificationDate: nil,
            eligibility: .eligible,
            evidence: .unknown("metadata unavailable"),
            reason: nil
        )
        let third = Finding(
            id: "app-1",
            category: .application,
            path: URL(fileURLWithPath: "/Applications/Example.app"),
            size: 5,
            modificationDate: nil,
            eligibility: .rejected,
            evidence: .observed("recently used"),
            reason: "Application removal is not supported"
        )
        let warning = ScanWarning(location: second.path, message: "Permission denied")

        let left = ScanSummary(findings: [first, second, third], warnings: [warning])
        let right = ScanSummary(findings: [third, second, first], warnings: [warning])

        XCTAssertEqual(left, right)
        XCTAssertEqual(left.findingCount, 3)
        XCTAssertEqual(left.eligibleCount, 1)
        XCTAssertEqual(left.readOnlyCount, 1)
        XCTAssertEqual(left.rejectedCount, 1)
        XCTAssertEqual(left.totalBytes, 35)
        XCTAssertEqual(left.eligibleBytes, 20)
        XCTAssertEqual(left.warningCount, 1)
    }

    /// Verifies a result derives its summary while retaining ambiguous evidence for the renderer.
    func testScanResultDerivesSummaryAndPreservesUnknownEvidence() {
        let finding = Finding(
            id: "app-1",
            category: .application,
            path: URL(fileURLWithPath: "/Applications/Example.app"),
            size: 42,
            modificationDate: nil,
            eligibility: .readOnly,
            evidence: .ambiguous("multiple usage signals"),
            reason: "Usage evidence needs review"
        )

        let result = ScanResult(findings: [finding])

        XCTAssertEqual(result.summary.findingCount, 1)
        XCTAssertEqual(result.summary.readOnlyCount, 1)
        XCTAssertEqual(result.findings.first?.evidence, .ambiguous("multiple usage signals"))
        XCTAssertEqual(result.findings.first?.reason, "Usage evidence needs review")
    }

    /// Verifies scan output exposes finding categories and category-level totals.
    func testScanOutputIncludesCategoriesAndCategoryTotals() {
        let result = ScanResult(findings: [
            Finding(
                id: "large-1",
                category: .largeFile,
                path: URL(fileURLWithPath: "/tmp/large.bin"),
                size: 10,
                modificationDate: nil,
                eligibility: .readOnly,
                evidence: nil,
                reason: nil
            ),
            Finding(
                id: "cache-1",
                category: .cache,
                path: URL(fileURLWithPath: "/tmp/cache"),
                size: 20,
                modificationDate: nil,
                eligibility: .eligible,
                evidence: nil,
                reason: nil
            )
        ])

        let output = CLIOutput.render(result)

        XCTAssertTrue(output.contains("largeFile: large.bin"))
        XCTAssertTrue(output.contains("cache: cache"))
        XCTAssertTrue(output.contains("largeFile: 1 findings"))
        XCTAssertTrue(output.contains("cache: 1 findings"))
    }
}

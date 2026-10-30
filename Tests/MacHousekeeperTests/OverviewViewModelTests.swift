import Foundation
import XCTest
@testable import MacHousekeeperApp
@testable import MacHousekeeperCore

@MainActor
final class OverviewViewModelTests: XCTestCase {
    /// Verifies an empty core result reaches the explicit empty overview state after background loading.
    func testOverviewViewModelReportsEmptyState() async {
        let snapshot = OverviewSnapshot(
            cacheResult: ScanResult(findings: []),
            memoryStatus: MemoryStatus(
                observedAt: Date(),
                physicalMemoryBytes: nil,
                availableMemoryBytes: nil,
                swapTotalBytes: nil,
                swapUsedBytes: nil,
                limitations: ["Memory indicators are unavailable."]
            )
        )
        let viewModel = OverviewViewModel { snapshot }

        viewModel.load()
        XCTAssertEqual(viewModel.state, .loading)

        for _ in 0..<100 {
            if viewModel.state == .empty(snapshot) { return }
            await Task.yield()
        }

        XCTFail("Overview did not finish loading")
    }
}

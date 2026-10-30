import Foundation
import MacHousekeeperCore

/// Contains the scan, selection, confirmation, and per-item results of one clean command.
struct CleanCommandResult: Equatable {
    let scan: ScanResult
    let selectedFindings: [Finding]
    let confirmed: Bool
    let outcomes: [CleanupOutcome]
}

/// Runs an interactive cache cleanup with a fresh scan and explicit confirmation boundary.
struct CleanCommand {
    let cacheLocations: [CacheLocation]
    private let input: () -> String?
    private let output: (String) -> Void
    private let remover: any RecoverableRemover

    /// Creates a command with injected input, output, and remover dependencies for tests.
    /// - Parameters:
    ///   - cacheLocations: Code-owned reviewed cache locations.
    ///   - input: One-line user input provider.
    ///   - output: Terminal output sink.
    ///   - remover: Recoverable removal implementation.
    init(
        cacheLocations: [CacheLocation],
        input: @escaping () -> String? = { readLine() },
        output: @escaping (String) -> Void = { print($0) },
        remover: any RecoverableRemover = FileManagerTrashRemover()
    ) {
        self.cacheLocations = cacheLocations
        self.input = input
        self.output = output
        self.remover = remover
    }

    /// Scans, previews, selects, confirms, and executes cache cleanup safely.
    /// - Returns: Complete command state and per-item outcomes.
    func run() -> CleanCommandResult {
        let scan = ScanCoordinator(cacheLocations: cacheLocations).scan(request: .scanCaches) { progress in
            guard progress.scannedItemCount > 0 else { return }
            output(CLIOutput.render(progress))
        }
        if !scan.warnings.isEmpty {
            output(CLIOutput.renderWarnings(scan.warnings))
        }
        let eligibleFindings = scan.findings.filter { $0.eligibility == .eligible }
        output(CLIOutput.renderCleanupPreview(eligibleFindings))

        guard !eligibleFindings.isEmpty else {
            return CleanCommandResult(scan: scan, selectedFindings: [], confirmed: false, outcomes: [])
        }

        output("Select item numbers separated by commas, 'all', or 'none':")
        let selection = input() ?? "none"
        guard let selectedIndexes = Self.parseSelection(selection, count: eligibleFindings.count) else {
            output("No valid selection was provided; no files were changed.")
            return CleanCommandResult(scan: scan, selectedFindings: [], confirmed: false, outcomes: [])
        }

        let selectedFindings = selectedIndexes.map { eligibleFindings[$0] }
        guard !selectedFindings.isEmpty else {
            output("Cleanup cancelled; no files were changed.")
            return CleanCommandResult(scan: scan, selectedFindings: [], confirmed: false, outcomes: [])
        }

        output(CLIOutput.renderCleanupPreview(selectedFindings))
        output("Confirm cleanup? Type 'yes' to move the selected items to Trash:")
        let confirmed = (input() ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "yes"
        let outcomes = CleanupExecutor(
            policy: CleanupPolicy(approvedCategories: cacheLocations),
            remover: remover
        ).execute(findings: selectedFindings, confirmed: confirmed)
        output(CLIOutput.render(outcomes))
        return CleanCommandResult(
            scan: scan,
            selectedFindings: selectedFindings,
            confirmed: confirmed,
            outcomes: outcomes
        )
    }

    /// Parses a bounded user selection into zero-based finding indexes.
    /// - Parameters:
    ///   - value: User input such as `all`, `none`, or `1,3`.
    ///   - count: Number of eligible findings displayed.
    /// - Returns: Sorted unique indexes, or `nil` for malformed input.
    private static func parseSelection(_ value: String, count: Int) -> [Int]? {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized == "all" { return Array(0..<count) }
        if normalized.isEmpty || normalized == "none" || normalized == "n" { return [] }

        let values = normalized.split(separator: ",", omittingEmptySubsequences: false)
        var indexes = Set<Int>()
        for value in values {
            guard let number = Int(value.trimmingCharacters(in: .whitespaces)), (1...count).contains(number) else {
                return nil
            }
            indexes.insert(number - 1)
        }
        return indexes.sorted()
    }
}

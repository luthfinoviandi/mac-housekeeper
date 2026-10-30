import Foundation
import MacHousekeeperCore

enum CLIOutput {
    static let help = """
    Usage: mac-housekeeper <command>

    Commands:
      scan large-files [--root PATH] [--min-size BYTES]
      scan caches
      scan apps
      memory
      clean caches
      help

    Cleanup is preview-only until a supported command explicitly asks for confirmation.
    """

    /// Writes a user-facing error and the command help to standard error.
    /// - Parameter message: Safe, user-facing explanation of the command failure.
    static func writeError(_ message: String) {
        let output = "Error: \(message)\n\n\(help)"
        FileHandle.standardError.write(Data(output.utf8))
    }

    /// Renders scan findings, warnings, and aggregate counts for terminal output.
    /// - Parameter result: Read-only provider result to render.
    /// - Returns: Human-readable scan report.
    static func render(_ result: ScanResult) -> String {
        var lines = ["Scan results"]
        if result.findings.isEmpty {
            lines.append("No findings.")
        } else {
            for finding in result.findings {
                let label = finding.displayName ?? finding.path.lastPathComponent
                lines.append("- \(finding.category.rawValue): \(label): \(formatBytes(finding.size)) — \(finding.path.path)")
                if let identifier = finding.identifier {
                    lines.append("  Identifier: \(identifier)")
                }
                if let modificationDate = finding.modificationDate {
                    lines.append("  Modified: \(formatDate(modificationDate))")
                }
                if let evidence = finding.evidence {
                    lines.append("  Evidence: \(describe(evidence))")
                }
                if let reason = finding.reason {
                    lines.append("  Note: \(reason)")
                }
            }
        }

        lines.append("")
        for category in FindingCategory.allCases {
            let categoryFindings = result.findings.filter { $0.category == category }
            guard !categoryFindings.isEmpty else { continue }
            let categoryBytes = categoryFindings.reduce(0) { $0 &+ $1.size }
            lines.append("\(category.rawValue): \(categoryFindings.count) findings, \(formatBytes(categoryBytes))")
        }
        lines.append("Summary: \(result.summary.findingCount) findings, \(formatBytes(result.summary.totalBytes))")
        if !result.warnings.isEmpty {
            lines.append("")
            lines.append(renderWarnings(result.warnings))
        }
        return lines.joined(separator: "\n")
    }

    /// Renders non-fatal scan limitations without exposing command internals.
    /// - Parameter warnings: Limitations collected during scanning.
    /// - Returns: Human-readable warning block.
    static func renderWarnings(_ warnings: [ScanWarning]) -> String {
        var lines = ["Warnings:"]
        for warning in warnings {
            let location = warning.location.map { " [\($0.path)]" } ?? ""
            lines.append("-\(location) \(warning.message)")
        }
        return lines.joined(separator: "\n")
    }

    /// Renders one progress event without exposing command internals or file contents.
    /// - Parameter progress: Provider progress event.
    /// - Returns: Human-readable progress line.
    static func render(_ progress: ScanProgress) -> String {
        "Scanning \(progress.providerName): \(progress.scannedItemCount) items, \(progress.findingCount) findings"
    }

    /// Renders the eligible items and estimated total for the cleanup selection prompt.
    /// - Parameter findings: Eligible findings available for this command.
    /// - Returns: Human-readable cleanup preview.
    static func renderCleanupPreview(_ findings: [Finding]) -> String {
        guard !findings.isEmpty else { return "Cleanup preview\nNo eligible cache findings." }
        let total = findings.reduce(0) { $0 &+ $1.size }
        var lines = ["Cleanup preview"]
        for (index, finding) in findings.enumerated() {
            lines.append("\(index + 1). \(finding.path.path) — \(formatBytes(finding.size))")
        }
        lines.append("Estimated reclaimable size: \(formatBytes(total))")
        return lines.joined(separator: "\n")
    }

    /// Renders completed, skipped, and failed cleanup outcomes with logical bytes moved to Trash.
    /// - Parameter outcomes: Per-item cleanup outcomes.
    /// - Returns: Human-readable cleanup result.
    static func render(_ outcomes: [CleanupOutcome]) -> String {
        guard !outcomes.isEmpty else { return "Cleanup result\nNo items were selected." }
        let completed = outcomes.contains { $0.result == .completed }
        let incomplete = outcomes.contains { $0.result != .completed }
        let status = completed && incomplete ? " — partial" : ""
        let movedBytes = outcomes.reduce(0) { $0 &+ $1.reclaimedBytes }
        var lines = ["Cleanup result\(status)"]
        for outcome in outcomes {
            let reason = outcome.reason.map { " — \($0)" } ?? ""
            lines.append("- \(outcome.findingID): \(outcome.result.rawValue)\(reason)")
        }
        lines.append("Logical size moved to Trash: \(formatBytes(movedBytes))")
        return lines.joined(separator: "\n")
    }

    /// Renders a timestamped memory observation and any unavailable indicators.
    /// - Parameter status: Memory status observation to render.
    /// - Returns: Human-readable memory report.
    static func render(_ status: MemoryStatus) -> String {
        var lines = [
            "Memory status",
            "Observed: \(formatDate(status.observedAt))",
            "Physical memory: \(status.physicalMemoryBytes.map(formatBytes) ?? "Unavailable")",
            "Available memory: \(status.availableMemoryBytes.map(formatBytes) ?? "Unavailable")",
            "Swap total: \(status.swapTotalBytes.map(formatBytes) ?? "Unavailable")",
            "Swap used: \(status.swapUsedBytes.map(formatBytes) ?? "Unavailable")"
        ]
        if !status.limitations.isEmpty {
            lines.append("")
            lines.append("Limitations:")
            lines.append(contentsOf: status.limitations.map { "- \($0)" })
        }
        return lines.joined(separator: "\n")
    }

    /// Formats a byte count using macOS's human-readable file size conventions.
    /// - Parameter bytes: Byte count to format.
    /// - Returns: Human-readable size string.
    private static func formatBytes(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .file)
    }

    /// Formats a timestamp using an unambiguous ISO-8601 representation.
    /// - Parameter date: Timestamp to format.
    /// - Returns: ISO-8601 timestamp.
    private static func formatDate(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    /// Converts an evidence state into the user-facing text for the report.
    /// - Parameter evidence: Evidence state to describe.
    /// - Returns: Evidence description preserving unknown and ambiguous states.
    private static func describe(_ evidence: EvidenceState) -> String {
        switch evidence {
        case let .observed(value): return value
        case let .unknown(reason): return "Unknown — \(reason)"
        case let .ambiguous(reason): return "Ambiguous — \(reason)"
        }
    }
}

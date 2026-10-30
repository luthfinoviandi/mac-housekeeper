import Foundation

/// Identifies the read-only scan domain that produced a finding.
public enum FindingCategory: String, Equatable, CaseIterable, Sendable {
    case largeFile
    case cache
    case application
}

/// Describes whether a finding may be considered by a later cleanup phase.
public enum FindingEligibility: String, Equatable, Sendable {
    case readOnly
    case eligible
    case rejected
}

/// Preserves the quality of optional evidence without converting uncertainty into a claim.
public enum EvidenceState: Equatable, Sendable {
    case observed(String)
    case unknown(String)
    case ambiguous(String)
}

/// Reports a non-fatal limitation encountered while scanning one location or datum.
public struct ScanWarning: Equatable, Sendable {
    public let location: URL?
    public let message: String

    /// Creates a non-fatal scan limitation.
    /// - Parameters:
    ///   - location: Optional location associated with the limitation.
    ///   - message: Safe user-facing explanation.
    public init(location: URL?, message: String) {
        self.location = location
        self.message = message
    }
}

/// Describes one item discovered by a read-only provider.
public struct Finding: Equatable, Sendable {
    public let id: String
    public let category: FindingCategory
    public let path: URL
    public let size: UInt64
    public let modificationDate: Date?
    public let eligibility: FindingEligibility
    public let evidence: EvidenceState?
    public let reason: String?
    public let displayName: String?
    public let identifier: String?

    /// Creates a finding, with optional application metadata for application inventory results.
    /// - Parameters:
    ///   - id: Stable identifier within the current command.
    ///   - category: Provider category that produced the finding.
    ///   - path: Absolute item URL.
    ///   - size: Logical or estimated item size in bytes.
    ///   - modificationDate: Optional filesystem modification date.
    ///   - eligibility: Whether a later cleanup phase may consider the item.
    ///   - evidence: Optional evidence state associated with the item.
    ///   - reason: Optional limitation or rejection explanation.
    ///   - displayName: Optional user-facing name, used for application bundles.
    ///   - identifier: Optional stable identifier, used for application bundles.
    public init(
        id: String,
        category: FindingCategory,
        path: URL,
        size: UInt64,
        modificationDate: Date?,
        eligibility: FindingEligibility,
        evidence: EvidenceState?,
        reason: String?,
        displayName: String? = nil,
        identifier: String? = nil
    ) {
        self.id = id
        self.category = category
        self.path = path
        self.size = size
        self.modificationDate = modificationDate
        self.eligibility = eligibility
        self.evidence = evidence
        self.reason = reason
        self.displayName = displayName
        self.identifier = identifier
    }
}

/// Carries periodic status from a provider without changing the scan result.
public struct ScanProgress: Equatable, Sendable {
    public let providerName: String
    public let scannedItemCount: Int
    public let findingCount: Int
    public let elapsedTime: TimeInterval

    /// Creates one provider progress event.
    /// - Parameters:
    ///   - providerName: Provider reporting progress.
    ///   - scannedItemCount: Number of items visited so far.
    ///   - findingCount: Number of findings produced so far.
    ///   - elapsedTime: Seconds since the provider started.
    public init(providerName: String, scannedItemCount: Int, findingCount: Int, elapsedTime: TimeInterval) {
        self.providerName = providerName
        self.scannedItemCount = scannedItemCount
        self.findingCount = findingCount
        self.elapsedTime = elapsedTime
    }
}

/// Aggregates findings and warnings into the stable summary shown at the output boundary.
public struct ScanSummary: Equatable, Sendable {
    public let findingCount: Int
    public let eligibleCount: Int
    public let readOnlyCount: Int
    public let rejectedCount: Int
    public let totalBytes: UInt64
    public let eligibleBytes: UInt64
    public let warningCount: Int

    /// Builds order-independent counts and byte totals from a provider result.
    ///
    /// The input order is intentionally ignored so filesystem enumeration order cannot change
    /// the summary rendered to the user.
    /// - Parameters:
    ///   - findings: Items discovered by the provider.
    ///   - warnings: Non-fatal limitations recorded during the scan.
    public init(findings: [Finding], warnings: [ScanWarning] = []) {
        findingCount = findings.count
        eligibleCount = findings.count { $0.eligibility == .eligible }
        readOnlyCount = findings.count { $0.eligibility == .readOnly }
        rejectedCount = findings.count { $0.eligibility == .rejected }
        totalBytes = findings.reduce(0) { $0 &+ $1.size }
        eligibleBytes = findings
            .filter { $0.eligibility == .eligible }
            .reduce(0) { $0 &+ $1.size }
        warningCount = warnings.count
    }
}

/// Contains all read-only output from one provider invocation.
public struct ScanResult: Equatable, Sendable {
    public let findings: [Finding]
    public let warnings: [ScanWarning]
    public let summary: ScanSummary

    /// Creates a result and derives its summary from the same findings and warnings.
    /// - Parameters:
    ///   - findings: Items discovered by the provider.
    ///   - warnings: Non-fatal limitations recorded during the scan.
    public init(findings: [Finding], warnings: [ScanWarning] = []) {
        self.findings = findings
        self.warnings = warnings
        summary = ScanSummary(findings: findings, warnings: warnings)
    }
}

/// Defines the synchronous interface shared by each read-only scan provider.
protocol ScanProvider {
    var name: String { get }

    /// Scans the provider's configured scope without mutating user data.
    /// - Parameter progress: Callback for periodic progress events.
    /// - Returns: Findings and warnings collected during the scan.
    func scan(progress: (ScanProgress) -> Void) -> ScanResult
}

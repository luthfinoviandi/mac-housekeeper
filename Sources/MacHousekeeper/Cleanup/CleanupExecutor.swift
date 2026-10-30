import Foundation
import MacHousekeeperCore

/// Describes the terminal result for one selected cleanup item.
enum CleanupOutcomeResult: String, Equatable {
    case completed
    case skipped
    case failed
}

/// Records one cleanup item's result and the bytes actually moved to recovery.
struct CleanupOutcome: Equatable {
    let findingID: String
    let result: CleanupOutcomeResult
    let reclaimedBytes: UInt64
    let reason: String?
}

/// Performs recoverable removal only after policy validation and explicit confirmation.
protocol RecoverableRemover {
    /// Moves one path to macOS Trash without falling back to permanent deletion.
    /// - Parameter path: Validated regular file or directory path.
    /// - Throws: Removal failure reported by the operating system.
    func moveToTrash(_ path: URL) throws
}

/// Uses FileManager's recoverable Trash operation for cleanup.
struct FileManagerTrashRemover: RecoverableRemover {
    private let fileManager: FileManager

    /// Creates a recoverable remover backed by the supplied filesystem implementation.
    /// - Parameter fileManager: Filesystem implementation used to move items to Trash.
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Moves the path to Trash and never performs permanent deletion.
    /// - Parameter path: Validated cleanup path.
    /// - Throws: FileManager error when the recoverable move fails.
    func moveToTrash(_ path: URL) throws {
        var resultingURL: NSURL?
        try fileManager.trashItem(at: path, resultingItemURL: &resultingURL)
    }
}

/// Executes selected findings serially while preserving an outcome for every item.
struct CleanupExecutor {
    let policy: CleanupPolicy
    private let remover: any RecoverableRemover

    /// Creates an executor with the policy and recoverable remover used by the command.
    /// - Parameters:
    ///   - policy: Allowlist and revalidation policy.
    ///   - remover: Recoverable removal implementation.
    init(policy: CleanupPolicy, remover: any RecoverableRemover = FileManagerTrashRemover()) {
        self.policy = policy
        self.remover = remover
    }

    /// Processes selected findings without mutating anything unless confirmation is explicit.
    /// - Parameters:
    ///   - findings: Findings selected during the current command.
    ///   - confirmed: Explicit confirmation state from the command boundary.
    /// - Returns: One completed, skipped, or failed outcome per selected finding.
    func execute(findings: [Finding], confirmed: Bool) -> [CleanupOutcome] {
        guard confirmed else {
            return findings.map {
                CleanupOutcome(
                    findingID: $0.id,
                    result: .skipped,
                    reclaimedBytes: 0,
                    reason: "Cleanup was not confirmed."
                )
            }
        }

        return findings.map { finding in
            switch policy.validate(finding) {
            case let .failure(rejection):
                return CleanupOutcome(
                    findingID: finding.id,
                    result: .skipped,
                    reclaimedBytes: 0,
                    reason: rejection.description
                )
            case let .success(target):
                do {
                    try remover.moveToTrash(target.path)
                    return CleanupOutcome(
                        findingID: finding.id,
                        result: .completed,
                        reclaimedBytes: target.currentSize,
                        reason: nil
                    )
                } catch {
                    return CleanupOutcome(
                        findingID: finding.id,
                        result: .failed,
                        reclaimedBytes: 0,
                        reason: "Recoverable removal failed."
                    )
                }
            }
        }
    }
}

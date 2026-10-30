import Foundation
import MacHousekeeperCore

/// Explains why a previewed cleanup finding cannot be mutated safely.
enum CleanupRejection: Error, Equatable, CustomStringConvertible {
    case unsupportedCategory
    case notEligible
    case unapprovedPath
    case missing
    case symbolicLink
    case unsupportedType
    case changedSize(expected: UInt64, actual: UInt64)
    case changedModificationDate
    case inaccessible

    /// Returns the user-facing reason for rejecting a cleanup target.
    var description: String {
        switch self {
        case .unsupportedCategory:
            return "Finding category is not approved for cleanup."
        case .notEligible:
            return "Finding is not currently eligible for cleanup."
        case .unapprovedPath:
            return "Path is outside the approved cleanup root."
        case .missing:
            return "Cleanup item no longer exists."
        case .symbolicLink:
            return "Symbolic links are not eligible for cleanup."
        case .unsupportedType:
            return "Cleanup item is not a regular file or directory."
        case let .changedSize(expected, actual):
            return "Item size changed from \(expected) bytes to \(actual) bytes."
        case .changedModificationDate:
            return "Item modification date changed."
        case .inaccessible:
            return "Cleanup item could not be fully revalidated."
        }
    }
}

/// Identifies a target that passed all pre-mutation checks.
struct ValidatedCleanupTarget: Equatable {
    let findingID: String
    let path: URL
    let currentSize: UInt64
}

/// Enforces code-owned cleanup roots and revalidates findings immediately before mutation.
struct CleanupPolicy {
    let approvedCategories: [CacheLocation]
    private let fileManager: FileManager

    /// Creates a policy from explicit, reviewed cache locations.
    /// - Parameters:
    ///   - approvedCategories: Code-owned cache locations allowed to contain eligible findings.
    ///   - fileManager: Filesystem implementation used for revalidation.
    init(approvedCategories: [CacheLocation], fileManager: FileManager = .default) {
        self.approvedCategories = approvedCategories
        self.fileManager = fileManager
    }

    /// Re-resolves and validates one previewed finding without changing the filesystem.
    /// - Parameter finding: Preview finding selected by the user in the current process.
    /// - Returns: A validated target or a typed rejection reason.
    func validate(_ finding: Finding) -> Result<ValidatedCleanupTarget, CleanupRejection> {
        guard finding.category == .cache else {
            return .failure(.unsupportedCategory)
        }
        guard finding.eligibility == .eligible else {
            return .failure(.notEligible)
        }

        guard let approvedCategory = approvedCategories.first(where: {
            $0.eligibility == .eligible
                && (try? fileManager.attributesOfItem(atPath: $0.root.path))?[.type] as? FileAttributeType != .typeSymbolicLink
                && isDescendant(finding.path, of: $0.root)
        }) else {
            return .failure(.unapprovedPath)
        }

        guard let attributes = try? fileManager.attributesOfItem(atPath: finding.path.path) else {
            return .failure(.missing)
        }
        guard let type = attributes[.type] as? FileAttributeType else {
            return .failure(.inaccessible)
        }
        guard type != .typeSymbolicLink else {
            return .failure(.symbolicLink)
        }
        guard type == .typeRegular || type == .typeDirectory else {
            return .failure(.unsupportedType)
        }

        let canonicalPath = finding.path.resolvingSymlinksInPath()
        let canonicalRoot = approvedCategory.root.resolvingSymlinksInPath()
        guard isDescendant(canonicalPath, of: canonicalRoot) else {
            return .failure(.unapprovedPath)
        }

        if let expectedModificationDate = finding.modificationDate {
            guard let actualModificationDate = try? finding.path.resourceValues(
                forKeys: [.contentModificationDateKey]
            ).contentModificationDate else {
                return .failure(.inaccessible)
            }
            guard actualModificationDate == expectedModificationDate else {
                return .failure(.changedModificationDate)
            }
        }

        var warnings: [ScanWarning] = []
        var currentSize: UInt64 = 0
        let itemCount = FileTreeWalker(fileManager: fileManager).walk(
            root: finding.path,
            onItem: { _, values in
                if values.isRegularFile == true, let fileSize = values.fileSize, fileSize >= 0 {
                    currentSize &+= UInt64(fileSize)
                }
            },
            onWarning: { warnings.append($0) }
        )

        if warnings.contains(where: { $0.message == "Symbolic links are not scanned." }) {
            return .failure(.symbolicLink)
        }
        guard itemCount > 0, warnings.isEmpty else {
            return .failure(.inaccessible)
        }
        guard currentSize == finding.size else {
            return .failure(.changedSize(expected: finding.size, actual: currentSize))
        }

        return .success(
            ValidatedCleanupTarget(
                findingID: finding.id,
                path: canonicalPath,
                currentSize: currentSize
            )
        )
    }

    /// Checks strict descendant containment after normalizing path aliases.
    /// - Parameters:
    ///   - candidate: Candidate item path.
    ///   - root: Approved cleanup root.
    /// - Returns: `true` only for a non-root descendant.
    private func isDescendant(_ candidate: URL, of root: URL) -> Bool {
        let candidatePath = candidate.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        guard candidatePath != rootPath else { return false }
        let prefix = rootPath.hasSuffix("/") ? rootPath : "\(rootPath)/"
        return candidatePath.hasPrefix(prefix)
    }
}

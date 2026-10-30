import Foundation

/// Walks a file URL without descending through symbolic links and reports access failures.
public struct FileTreeWalker {
    private let fileManager: FileManager

    /// Returns whether filesystem attributes identify the URL itself as a symbolic link.
    /// - Parameter url: File URL whose link type should be checked without following it.
    /// - Returns: `true` only when the URL's own directory entry is a symbolic link.
    private func isSymbolicLink(_ url: URL) -> Bool {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path) else {
            return false
        }
        return (attributes[.type] as? FileAttributeType) == .typeSymbolicLink
    }

    /// Creates a walker using the supplied filesystem implementation.
    /// - Parameter fileManager: Filesystem implementation used for enumeration.
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Visits readable files and directories below a root, skipping symbolic links.
    /// - Parameters:
    ///   - root: File URL to inspect.
    ///   - onItem: Receives each readable non-symbolic-link item.
    ///   - onWarning: Receives non-fatal traversal limitations.
    /// - Returns: Number of items delivered to `onItem`.
    public func walk(
        root: URL,
        onItem: (URL, URLResourceValues) -> Void,
        onWarning: @escaping (ScanWarning) -> Void
    ) -> Int {
        let keys: Set<URLResourceKey> = [
            .contentModificationDateKey,
            .fileSizeKey,
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey
        ]

        guard root.isFileURL else {
            onWarning(ScanWarning(location: root, message: "Only file URLs can be scanned."))
            return 0
        }

        if isSymbolicLink(root) {
            onWarning(ScanWarning(location: root, message: "Symbolic links are not scanned."))
            return 0
        }

        guard let rootValues = try? root.resourceValues(forKeys: keys) else {
            onWarning(ScanWarning(location: root, message: "Location could not be inspected."))
            return 0
        }

        if rootValues.isDirectory == true {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: Array(keys),
                options: [],
                errorHandler: { url, error in
                    onWarning(ScanWarning(location: url, message: error.localizedDescription))
                    return true
                }
            ) else {
                onWarning(ScanWarning(location: root, message: "Location could not be enumerated."))
                return 0
            }

            var itemCount = 0
            while let item = enumerator.nextObject() as? URL {
                if isSymbolicLink(item) {
                    enumerator.skipDescendants()
                    onWarning(ScanWarning(location: item, message: "Symbolic links are not scanned."))
                    continue
                }

                guard let values = try? item.resourceValues(forKeys: keys) else {
                    onWarning(ScanWarning(location: item, message: "Item metadata could not be read."))
                    continue
                }

                onItem(item, values)
                itemCount += 1
            }
            return itemCount
        }

        onItem(root, rootValues)
        return 1
    }
}

/// Finds regular files at or above a typed byte threshold without mutating the filesystem.
struct FileScanner: ScanProvider {
    let root: URL
    let minimumSize: UInt64
    let progressInterval: TimeInterval
    private let fileManager: FileManager

    /// Creates a large-file scanner for one local filesystem root.
    /// - Parameters:
    ///   - root: File URL to inspect.
    ///   - minimumSize: Inclusive minimum logical file size in bytes.
    ///   - progressInterval: Minimum interval between periodic progress events.
    ///   - fileManager: Filesystem implementation used for enumeration.
    init(
        root: URL,
        minimumSize: UInt64,
        progressInterval: TimeInterval = 2,
        fileManager: FileManager = .default
    ) {
        self.root = root.standardizedFileURL
        self.minimumSize = minimumSize
        self.progressInterval = max(0, progressInterval)
        self.fileManager = fileManager
    }

    var name: String { "large-files" }

    /// Scans the configured root and reports matching regular files in stable order.
    /// - Parameter progress: Receives an initial, periodic, and final progress event.
    /// - Returns: Matching findings and non-fatal traversal warnings.
    func scan(progress: (ScanProgress) -> Void) -> ScanResult {
        let startedAt = Date()
        var warnings: [ScanWarning] = []
        var candidates: [(url: URL, size: UInt64, modificationDate: Date?)] = []
        var scannedItemCount = 0
        var lastProgressAt = startedAt

        progress(ScanProgress(providerName: name, scannedItemCount: 0, findingCount: 0, elapsedTime: 0))

        if minimumSize == 0 {
            warnings.append(ScanWarning(location: root, message: "Minimum file size must be greater than zero."))
        } else {
            _ = FileTreeWalker(fileManager: fileManager).walk(
                root: root,
                onItem: { url, values in
                    scannedItemCount += 1
                    if values.isRegularFile == true, let fileSize = values.fileSize, fileSize >= 0 {
                        let size = UInt64(fileSize)
                        if size >= minimumSize {
                            candidates.append((url, size, values.contentModificationDate))
                        }
                    }

                    let now = Date()
                    if now.timeIntervalSince(lastProgressAt) >= progressInterval {
                        progress(
                            ScanProgress(
                                providerName: name,
                                scannedItemCount: scannedItemCount,
                                findingCount: candidates.count,
                                elapsedTime: now.timeIntervalSince(startedAt)
                            )
                        )
                        lastProgressAt = now
                    }
                },
                onWarning: { warnings.append($0) }
            )
        }

        candidates.sort { left, right in
            if left.size != right.size {
                return left.size > right.size
            }
            return left.url.path < right.url.path
        }

        let findings = candidates.enumerated().map { index, candidate in
            Finding(
                id: "large-file-\(index + 1)",
                category: .largeFile,
                path: candidate.url,
                size: candidate.size,
                modificationDate: candidate.modificationDate,
                eligibility: .readOnly,
                evidence: nil,
                reason: nil
            )
        }

        progress(
            ScanProgress(
                providerName: name,
                scannedItemCount: scannedItemCount,
                findingCount: findings.count,
                elapsedTime: Date().timeIntervalSince(startedAt)
            )
        )
        return ScanResult(findings: findings, warnings: warnings)
    }
}

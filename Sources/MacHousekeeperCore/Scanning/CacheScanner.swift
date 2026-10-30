import Foundation

/// Describes one code-owned cache location and whether its findings are cleanup eligible.
public struct CacheLocation: Equatable, Sendable {
    public let name: String
    public let root: URL
    public let eligibility: FindingEligibility

    /// Creates a cache location supplied by the reviewed cache policy.
    /// - Parameters:
    ///   - name: Human-readable policy category name.
    ///   - root: User-owned cache directory to inspect.
    ///   - eligibility: Policy decision for items found below this location.
    public init(name: String, root: URL, eligibility: FindingEligibility) {
        self.name = name
        self.root = root.standardizedFileURL
        self.eligibility = eligibility
    }
}

/// Scans explicitly supplied cache locations and never infers cleanup approval from a path.
struct CacheScanner: ScanProvider {
    let locations: [CacheLocation]
    let progressInterval: TimeInterval
    private let fileManager: FileManager

    /// Creates a cache scanner from the caller's code-owned reviewed locations.
    /// - Parameters:
    ///   - locations: Allowlisted locations; arbitrary CLI paths must not be passed here.
    ///   - progressInterval: Minimum interval between periodic progress events.
    ///   - fileManager: Filesystem implementation used for enumeration.
    init(
        locations: [CacheLocation],
        progressInterval: TimeInterval = 2,
        fileManager: FileManager = .default
    ) {
        self.locations = locations
        self.progressInterval = max(0, progressInterval)
        self.fileManager = fileManager
    }

    var name: String { "caches" }

    /// Scans each allowlisted location and reports its immediate children by estimated size.
    /// - Parameter progress: Receives an initial, periodic, and final progress event.
    /// - Returns: Cache findings and non-fatal traversal warnings.
    func scan(progress: (ScanProgress) -> Void) -> ScanResult {
        let startedAt = Date()
        var warnings: [ScanWarning] = []
        var findings: [Finding] = []
        var scannedItemCount = 0
        var lastProgressAt = startedAt

        progress(ScanProgress(providerName: name, scannedItemCount: 0, findingCount: 0, elapsedTime: 0))

        for location in locations {
            let root = location.root
            if (try? fileManager.attributesOfItem(atPath: root.path))?[.type] as? FileAttributeType == .typeSymbolicLink {
                warnings.append(ScanWarning(location: root, message: "Symbolic links are not scanned."))
                continue
            }
            let keys: Set<URLResourceKey> = [.contentModificationDateKey, .isDirectoryKey, .isSymbolicLinkKey]
            let children: [URL]

            do {
                children = try fileManager.contentsOfDirectory(
                    at: root,
                    includingPropertiesForKeys: Array(keys),
                    options: []
                )
            } catch {
                warnings.append(ScanWarning(location: root, message: error.localizedDescription))
                continue
            }

            for child in children.sorted(by: { $0.path < $1.path }) {
                if (try? fileManager.attributesOfItem(atPath: child.path))?[.type] as? FileAttributeType == .typeSymbolicLink {
                    warnings.append(ScanWarning(location: child, message: "Symbolic links are not scanned."))
                    continue
                }

                guard let childValues = try? child.resourceValues(forKeys: keys) else {
                    warnings.append(ScanWarning(location: child, message: "Item metadata could not be read."))
                    continue
                }

                var size: UInt64 = 0
                let itemCount = FileTreeWalker(fileManager: fileManager).walk(
                    root: child,
                    onItem: { _, values in
                        scannedItemCount += 1
                        if values.isRegularFile == true, let fileSize = values.fileSize, fileSize >= 0 {
                            size &+= UInt64(fileSize)
                        }

                        let now = Date()
                        if now.timeIntervalSince(lastProgressAt) >= progressInterval {
                            progress(
                                ScanProgress(
                                    providerName: name,
                                    scannedItemCount: scannedItemCount,
                                    findingCount: findings.count,
                                    elapsedTime: now.timeIntervalSince(startedAt)
                                )
                            )
                            lastProgressAt = now
                        }
                    },
                    onWarning: { warnings.append($0) }
                )

                guard itemCount > 0, size > 0 else { continue }

                findings.append(
                    Finding(
                        id: "cache-\(findings.count + 1)",
                        category: .cache,
                        path: child,
                        size: size,
                        modificationDate: childValues.contentModificationDate,
                        eligibility: location.eligibility,
                        evidence: nil,
                        reason: location.eligibility == .eligible
                            ? nil
                            : "Location is not approved for cleanup."
                    )
                )
            }
        }

        findings.sort { left, right in
            if left.size != right.size {
                return left.size > right.size
            }
            return left.path.path < right.path.path
        }

        findings = findings.enumerated().map { index, finding in
            Finding(
                id: "cache-\(index + 1)",
                category: finding.category,
                path: finding.path,
                size: finding.size,
                modificationDate: finding.modificationDate,
                eligibility: finding.eligibility,
                evidence: finding.evidence,
                reason: finding.reason,
                displayName: finding.displayName,
                identifier: finding.identifier
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

import Foundation

/// Supplies optional usage evidence without allowing the scanner to infer usage from absence.
protocol ApplicationUsageEvidenceProvider {
    /// Reads usage evidence for one application bundle without mutating the bundle.
    /// - Parameter applicationURL: Application bundle to inspect.
    /// - Returns: Observed, unknown, or ambiguous evidence state.
    func evidence(for applicationURL: URL) -> EvidenceState
}

/// Reads Spotlight's last-used metadata through a fixed executable and separate arguments.
struct MetadataApplicationUsageProvider: ApplicationUsageEvidenceProvider {
    private let executableURL = URL(fileURLWithPath: "/usr/bin/mdls")
    private let timeout: TimeInterval

    /// Creates a metadata provider with a bounded wait for Spotlight queries.
    /// - Parameter timeout: Maximum time to wait before terminating the query.
    init(timeout: TimeInterval = 1) {
        self.timeout = max(0, timeout)
    }

    /// Runs the supported metadata query and maps missing or malformed output to unknown.
    /// - Parameter applicationURL: Application bundle whose usage metadata is requested.
    /// - Returns: A non-fabricated usage evidence state.
    func evidence(for applicationURL: URL) -> EvidenceState {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = executableURL
        process.arguments = ["-name", "kMDItemLastUsedDate", "-raw", applicationURL.path]
        process.standardOutput = outputPipe
        process.standardError = FileHandle(forWritingAtPath: "/dev/null")

        do {
            try process.run()
            let deadline = Date().addingTimeInterval(timeout)
            while process.isRunning, Date() < deadline {
                RunLoop.current.run(until: Date().addingTimeInterval(0.01))
            }
            guard !process.isRunning else {
                process.terminate()
                return .unknown("Usage metadata request timed out.")
            }
        } catch {
            return .unknown("Usage metadata is unavailable.")
        }

        guard process.terminationStatus == 0 else {
            return .unknown("Usage metadata is unavailable.")
        }

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let output, !output.isEmpty, output != "(null)", output.lowercased() != "null" else {
            return .unknown("Usage metadata is unavailable.")
        }

        return .observed("Last used: \(output)")
    }
}

/// Inventories application bundles in explicitly configured macOS application roots.
struct ApplicationScanner: ScanProvider {
    let roots: [URL]
    let progressInterval: TimeInterval
    private let usageProvider: any ApplicationUsageEvidenceProvider
    private let fileManager: FileManager

    /// The standard application roots covered by the MVP.
    static var defaultRoots: [URL] {
        [
            URL(fileURLWithPath: "/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
    }

    /// Creates an application scanner for the standard roots or injected fixture roots.
    /// - Parameters:
    ///   - roots: Application directories to inspect.
    ///   - usageProvider: Controlled provider for optional usage evidence.
    ///   - progressInterval: Minimum interval between periodic progress events.
    ///   - fileManager: Filesystem implementation used for enumeration.
    init(
        roots: [URL] = ApplicationScanner.defaultRoots,
        usageProvider: any ApplicationUsageEvidenceProvider = MetadataApplicationUsageProvider(),
        progressInterval: TimeInterval = 2,
        fileManager: FileManager = .default
    ) {
        self.roots = roots.map(\.standardizedFileURL)
        self.usageProvider = usageProvider
        self.progressInterval = max(0, progressInterval)
        self.fileManager = fileManager
    }

    var name: String { "apps" }

    /// Scans application bundles and reports metadata, installed size, and evidence state.
    /// - Parameter progress: Receives an initial, periodic, and final progress event.
    /// - Returns: Application findings and non-fatal root or bundle warnings.
    func scan(progress: (ScanProgress) -> Void) -> ScanResult {
        let startedAt = Date()
        var warnings: [ScanWarning] = []
        var findings: [Finding] = []
        var scannedItemCount = 0
        var lastProgressAt = startedAt

        progress(ScanProgress(providerName: name, scannedItemCount: 0, findingCount: 0, elapsedTime: 0))

        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey]
        for root in roots {
            if (try? fileManager.attributesOfItem(atPath: root.path))?[.type] as? FileAttributeType == .typeSymbolicLink {
                warnings.append(ScanWarning(location: root, message: "Symbolic links are not scanned."))
                continue
            }
            let entries: [URL]
            do {
                entries = try fileManager.contentsOfDirectory(
                    at: root,
                    includingPropertiesForKeys: Array(resourceKeys),
                    options: []
                )
            } catch {
                warnings.append(ScanWarning(location: root, message: error.localizedDescription))
                continue
            }

            for entry in entries.sorted(by: { $0.path < $1.path }) {
                guard entry.pathExtension.caseInsensitiveCompare("app") == .orderedSame else {
                    continue
                }

                if (try? fileManager.attributesOfItem(atPath: entry.path))?[.type] as? FileAttributeType == .typeSymbolicLink {
                    warnings.append(ScanWarning(location: entry, message: "Symbolic links are not scanned."))
                    continue
                }

                guard let bundle = Bundle(url: entry), let info = bundle.infoDictionary else {
                    warnings.append(ScanWarning(location: entry, message: "Application metadata could not be read."))
                    continue
                }

                let displayName = (info["CFBundleDisplayName"] as? String)
                    ?? (info["CFBundleName"] as? String)
                    ?? entry.deletingPathExtension().lastPathComponent
                let identifier = info["CFBundleIdentifier"] as? String
                var installedSize: UInt64 = 0
                let itemCount = FileTreeWalker(fileManager: fileManager).walk(
                    root: entry,
                    onItem: { _, values in
                        scannedItemCount += 1
                        if values.isRegularFile == true, let fileSize = values.fileSize, fileSize >= 0 {
                            installedSize &+= UInt64(fileSize)
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

                guard itemCount > 0 else { continue }

                findings.append(
                    Finding(
                        id: "application-\(findings.count + 1)",
                        category: .application,
                        path: entry,
                        size: installedSize,
                        modificationDate: (try? entry.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate,
                        eligibility: .readOnly,
                        evidence: usageProvider.evidence(for: entry),
                        reason: identifier == nil ? "Bundle identifier is unavailable." : nil,
                        displayName: displayName,
                        identifier: identifier
                    )
                )
            }
        }

        findings.sort { left, right in
            left.path.path < right.path.path
        }
        findings = findings.enumerated().map { index, finding in
            Finding(
                id: "application-\(index + 1)",
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

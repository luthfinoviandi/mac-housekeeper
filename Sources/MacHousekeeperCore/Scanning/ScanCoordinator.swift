import Foundation

/// Selects read-only providers and returns one aggregated result for a scan command.
public struct ScanCoordinator: Sendable {
    let defaultLargeFileRoot: URL
    let defaultLargeFileMinimumSize: UInt64
    let cacheLocations: [CacheLocation]
    let applicationRoots: [URL]
    let progressInterval: TimeInterval

    /// Creates a coordinator with safe defaults and injectable roots for tests.
    /// - Parameters:
    ///   - defaultLargeFileRoot: Root used when the command omits `--root`.
    ///   - defaultLargeFileMinimumSize: Product default threshold in bytes.
    ///   - cacheLocations: Code-owned reviewed cache locations.
    ///   - applicationRoots: Application roots passed to the application provider.
    ///   - progressInterval: Provider progress interval.
    public init(
        defaultLargeFileRoot: URL = FileManager.default.homeDirectoryForCurrentUser,
        defaultLargeFileMinimumSize: UInt64 = 1_000_000_000,
        cacheLocations: [CacheLocation] = [],
        applicationRoots: [URL]? = nil,
        progressInterval: TimeInterval = 2
    ) {
        self.defaultLargeFileRoot = defaultLargeFileRoot.standardizedFileURL
        self.defaultLargeFileMinimumSize = defaultLargeFileMinimumSize
        self.cacheLocations = cacheLocations
        self.applicationRoots = applicationRoots ?? ApplicationScanner.defaultRoots
        self.progressInterval = max(0, progressInterval)
    }

    /// Selects the provider matching a typed read-only request and forwards its progress events.
    /// - Parameters:
    ///   - request: Read-only scan request supplied by a caller.
    ///   - progress: Receives provider progress events.
    /// - Returns: Provider findings and warnings.
    public func scan(request: ScanRequest, progress: (ScanProgress) -> Void = { _ in }) -> ScanResult {
        switch request {
        case let .scanLargeFiles(root, minimumSize):
            return FileScanner(
                root: root ?? defaultLargeFileRoot,
                minimumSize: minimumSize ?? defaultLargeFileMinimumSize,
                progressInterval: progressInterval
            ).scan(progress: progress)
        case .scanCaches:
            var result = CacheScanner(
                locations: cacheLocations,
                progressInterval: progressInterval
            ).scan(progress: progress)
            if cacheLocations.isEmpty {
                result = ScanResult(
                    findings: result.findings,
                    warnings: result.warnings + [
                        ScanWarning(location: nil, message: "No reviewed cache locations are available.")
                    ]
                )
            }
            return result
        case .scanApplications:
            return ApplicationScanner(
                roots: applicationRoots,
                progressInterval: progressInterval
            ).scan(progress: progress)
        }
    }
}

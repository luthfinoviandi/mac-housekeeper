import Foundation

/// Provides the narrow, code-owned cache locations approved for cleanup.
public enum ReviewedCacheCatalog {
    /// Returns existing, non-symlinked macOS service caches below the current user's Library.
    /// - Parameters:
    ///   - homeDirectory: User home used to resolve the catalog in tests and production.
    ///   - fileManager: Filesystem implementation used to exclude absent or symlinked roots.
    /// - Returns: Reviewed regenerable cache locations eligible for cleanup.
    public static func locations(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default
    ) -> [CacheLocation] {
        let cacheRoot = homeDirectory.appendingPathComponent("Library/Caches", isDirectory: true)
        let candidates = [
            ("macOS help cache", "com.apple.helpd"),
            ("macOS icon services cache", "com.apple.iconservices"),
            ("macOS Quick Look thumbnail cache", "com.apple.quicklook.ThumbnailsAgent")
        ]

        return candidates.compactMap { name, path in
            let root = cacheRoot.appendingPathComponent(path, isDirectory: true)
            guard let attributes = try? fileManager.attributesOfItem(atPath: root.path),
                  attributes[.type] as? FileAttributeType == .typeDirectory,
                  attributes[.type] as? FileAttributeType != .typeSymbolicLink else {
                return nil
            }
            return CacheLocation(name: name, root: root, eligibility: .eligible)
        }
    }
}

import Foundation

/// Describes one supported read-only scan without depending on a terminal parser.
public enum ScanRequest: Equatable, Sendable {
    case scanLargeFiles(root: URL?, minimumSize: UInt64?)
    case scanCaches
    case scanApplications
}

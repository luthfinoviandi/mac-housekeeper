import Foundation
import MacHousekeeperCore

enum CLICommand: Equatable {
    case help
    case scanLargeFiles(root: URL?, minimumSize: UInt64?)
    case scanCaches
    case scanApplications
    case memory
    case cleanCaches

    var summary: String {
        switch self {
        case .help:
            return "help"
        case .scanLargeFiles:
            return "scan large-files"
        case .scanCaches:
            return "scan caches"
        case .scanApplications:
            return "scan apps"
        case .memory:
            return "memory"
        case .cleanCaches:
            return "clean caches"
        }
    }

    /// Maps a parsed read-only CLI scan onto the core request type without exposing CLI parsing to Core.
    var scanRequest: ScanRequest? {
        switch self {
        case let .scanLargeFiles(root, minimumSize):
            return .scanLargeFiles(root: root, minimumSize: minimumSize)
        case .scanCaches:
            return .scanCaches
        case .scanApplications:
            return .scanApplications
        default:
            return nil
        }
    }
}

import Foundation

enum CLIParseError: Error, Equatable, CustomStringConvertible {
    case unknownCommand(String)
    case missingValue(String)
    case invalidValue(option: String, value: String)
    case unexpectedArgument(String)

    var description: String {
        switch self {
        case let .unknownCommand(command):
            return "Unknown command: \(command)"
        case let .missingValue(option):
            return "Missing value for \(option)"
        case let .invalidValue(option, value):
            return "Invalid value for \(option): \(value)"
        case let .unexpectedArgument(argument):
            return "Unexpected argument: \(argument)"
        }
    }
}

struct CLIParser {
    func parse(_ arguments: [String]) throws -> CLICommand {
        guard let first = arguments.first else {
            return .help
        }

        switch first {
        case "help", "--help", "-h":
            guard arguments.count == 1 else {
                throw CLIParseError.unexpectedArgument(arguments[1])
            }
            return .help
        case "scan":
            return try parseScan(Array(arguments.dropFirst()))
        case "memory":
            guard arguments.count == 1 else {
                throw CLIParseError.unexpectedArgument(arguments[1])
            }
            return .memory
        case "clean":
            return try parseClean(Array(arguments.dropFirst()))
        default:
            throw CLIParseError.unknownCommand(first)
        }
    }

    private func parseScan(_ arguments: [String]) throws -> CLICommand {
        guard let scanType = arguments.first else {
            throw CLIParseError.missingValue("scan type")
        }

        switch scanType {
        case "caches":
            guard arguments.count == 1 else {
                throw CLIParseError.unexpectedArgument(arguments[1])
            }
            return .scanCaches
        case "apps":
            guard arguments.count == 1 else {
                throw CLIParseError.unexpectedArgument(arguments[1])
            }
            return .scanApplications
        case "large-files":
            return try parseLargeFileOptions(Array(arguments.dropFirst()))
        default:
            throw CLIParseError.unknownCommand("scan \(scanType)")
        }
    }

    private func parseLargeFileOptions(_ arguments: [String]) throws -> CLICommand {
        var root: URL?
        var minimumSize: UInt64?
        var index = 0

        while index < arguments.count {
            let option = arguments[index]
            switch option {
            case "--root":
                index += 1
                guard index < arguments.count else {
                    throw CLIParseError.missingValue(option)
                }
                root = URL(
                    fileURLWithPath: arguments[index],
                    relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                ).standardizedFileURL
            case "--min-size":
                index += 1
                guard index < arguments.count else {
                    throw CLIParseError.missingValue(option)
                }
                let value = arguments[index]
                guard let parsed = UInt64(value), parsed > 0 else {
                    throw CLIParseError.invalidValue(option: option, value: value)
                }
                minimumSize = parsed
            default:
                throw CLIParseError.unexpectedArgument(option)
            }
            index += 1
        }

        return .scanLargeFiles(root: root, minimumSize: minimumSize)
    }

    private func parseClean(_ arguments: [String]) throws -> CLICommand {
        guard arguments.first == "caches" else {
            throw CLIParseError.unknownCommand("clean \(arguments.first ?? "")".trimmingCharacters(in: .whitespaces))
        }
        guard arguments.count == 1 else {
            throw CLIParseError.unexpectedArgument(arguments[1])
        }
        return .cleanCaches
    }
}

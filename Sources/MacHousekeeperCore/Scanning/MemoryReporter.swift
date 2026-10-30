import Foundation

/// Captures the result of one fixed-path system command invocation.
struct SystemCommandOutput: Equatable {
    let status: Int32
    let standardOutput: String
}

/// Runs fixed platform executables without constructing shell command strings.
protocol SystemCommandRunner {
    /// Runs one executable with separately supplied arguments.
    /// - Parameters:
    ///   - executable: Absolute executable URL selected by the provider.
    ///   - arguments: Validated argument values passed directly to the process.
    /// - Returns: Process status and standard output, or `nil` when launch fails.
    func run(executable: URL, arguments: [String]) -> SystemCommandOutput?
}

/// Executes a supported macOS process and suppresses uncontrolled stderr output.
struct ProcessSystemCommandRunner: SystemCommandRunner {
    let timeout: TimeInterval

    /// Creates a process runner with a bounded wait for platform commands.
    /// - Parameter timeout: Maximum time to wait before terminating the process.
    init(timeout: TimeInterval = 5) {
        self.timeout = max(0, timeout)
    }

    /// Runs the executable directly and captures only its standard output.
    /// - Parameters:
    ///   - executable: Absolute executable URL.
    ///   - arguments: Separate process arguments.
    /// - Returns: Process status and captured output, or `nil` when the process cannot launch.
    func run(executable: URL, arguments: [String]) -> SystemCommandOutput? {
        let process = Process()
        let outputPipe = Pipe()
        process.executableURL = executable
        process.arguments = arguments
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
                return nil
            }
        } catch {
            return nil
        }

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return SystemCommandOutput(status: process.terminationStatus, standardOutput: output)
    }
}

/// Reports a point-in-time memory and swap observation without attempting to alter memory state.
public struct MemoryStatus: Equatable, Sendable {
    public let observedAt: Date
    public let physicalMemoryBytes: UInt64?
    public let availableMemoryBytes: UInt64?
    public let swapTotalBytes: UInt64?
    public let swapUsedBytes: UInt64?
    public let limitations: [String]
}

/// Reads Foundation memory information and optional macOS memory-pressure indicators.
public struct MemoryReporter {
    private let processInfo: ProcessInfo
    private let commandRunner: any SystemCommandRunner

    /// Creates a reporter with injectable process and command dependencies for tests.
    /// - Parameters:
    ///   - processInfo: Foundation source for physical memory.
    ///   - commandRunner: Fixed-path command runner for optional indicators.
    public init() {
        self.init(processInfo: .processInfo, commandRunner: ProcessSystemCommandRunner())
    }

    /// Creates a reporter with injectable dependencies for tests.
    /// - Parameters:
    ///   - processInfo: Foundation source for physical memory.
    ///   - commandRunner: Fixed-path command runner for optional indicators.
    init(
        processInfo: ProcessInfo = .processInfo,
        commandRunner: any SystemCommandRunner = ProcessSystemCommandRunner()
    ) {
        self.processInfo = processInfo
        self.commandRunner = commandRunner
    }

    /// Captures physical memory, available memory, swap usage, and explicit limitations.
    /// - Returns: One timestamped memory status observation.
    public func report() -> MemoryStatus {
        let observedAt = Date()
        let physicalMemory = processInfo.physicalMemory
        var limitations: [String] = []

        let vmOutput = commandRunner.run(
            executable: URL(fileURLWithPath: "/usr/bin/vm_stat"),
            arguments: []
        )
        let availableMemory: UInt64?
        if let vmOutput, vmOutput.status == 0 {
            availableMemory = Self.parseAvailableMemory(from: vmOutput.standardOutput)
        } else {
            availableMemory = nil
        }
        if availableMemory == nil {
            limitations.append("Available memory indicator is unavailable.")
        }

        let swapOutput = commandRunner.run(
            executable: URL(fileURLWithPath: "/usr/sbin/sysctl"),
            arguments: ["-n", "vm.swapusage"]
        )
        let swapValues: (total: UInt64, used: UInt64)?
        if let swapOutput, swapOutput.status == 0 {
            swapValues = Self.parseSwapUsage(from: swapOutput.standardOutput)
        } else {
            swapValues = nil
        }
        if swapValues == nil {
            limitations.append("Swap usage indicators are unavailable.")
        }

        return MemoryStatus(
            observedAt: observedAt,
            physicalMemoryBytes: physicalMemory == 0 ? nil : physicalMemory,
            availableMemoryBytes: availableMemory,
            swapTotalBytes: swapValues?.total,
            swapUsedBytes: swapValues?.used,
            limitations: limitations
        )
    }

    /// Parses vm_stat page counters into available bytes.
    /// - Parameter output: Standard output from `/usr/bin/vm_stat`.
    /// - Returns: Free plus inactive and speculative pages in bytes, or `nil` if incomplete.
    private static func parseAvailableMemory(from output: String) -> UInt64? {
        var pageSize: UInt64?
        var pageCounts: [String: UInt64] = [:]

        for line in output.split(separator: "\n") {
            let text = String(line)
            if text.contains("page size of") {
                pageSize = firstUInt64(in: text)
            }
            for label in ["Pages free:", "Pages inactive:", "Pages speculative:"] where text.hasPrefix(label) {
                if let value = firstUInt64(in: text) {
                    pageCounts[label] = value
                }
            }
        }

        guard let pageSize,
              let free = pageCounts["Pages free:"],
              let inactive = pageCounts["Pages inactive:"],
              let speculative = pageCounts["Pages speculative:"] else {
            return nil
        }

        let (freeAndInactive, firstOverflow) = free.addingReportingOverflow(inactive)
        let (totalPages, secondOverflow) = freeAndInactive.addingReportingOverflow(speculative)
        let (availableBytes, thirdOverflow) = totalPages.multipliedReportingOverflow(by: pageSize)
        guard !firstOverflow, !secondOverflow, !thirdOverflow else { return nil }
        return availableBytes
    }

    /// Parses vm.swapusage's total and used byte values.
    /// - Parameter output: Standard output from `/usr/sbin/sysctl -n vm.swapusage`.
    /// - Returns: Total and used swap bytes, or `nil` if either value is malformed.
    private static func parseSwapUsage(from output: String) -> (total: UInt64, used: UInt64)? {
        let tokens = output.split { $0 == " " || $0 == "\n" || $0 == "\t" }

        guard let total = parseSwapValue(after: "total", in: tokens),
              let used = parseSwapValue(after: "used", in: tokens) else {
            return nil
        }
        return (total, used)
    }

    /// Reads the byte value following a named swapusage field.
    /// - Parameters:
    ///   - label: Field name such as `total` or `used`.
    ///   - tokens: Whitespace-separated swapusage output.
    /// - Returns: Parsed byte count, if the field is present and valid.
    private static func parseSwapValue(after label: String, in tokens: [Substring]) -> UInt64? {
        guard let index = tokens.firstIndex(where: { $0 == Substring(label) }), index + 2 < tokens.endIndex else {
            return nil
        }
        return parseByteValue(String(tokens[index + 2]))
    }

    /// Extracts the first decimal integer from a platform command line.
    /// - Parameter text: Command output line.
    /// - Returns: First unsigned integer, if present.
    private static func firstUInt64(in text: String) -> UInt64? {
        let digits = text.split { !$0.isNumber }.first
        return digits.flatMap { UInt64($0) }
    }

    /// Converts a decimal byte quantity with an optional binary unit suffix.
    /// - Parameter value: Value such as `4096.00M`.
    /// - Returns: Rounded byte count, if the value is valid.
    private static func parseByteValue(_ value: String) -> UInt64? {
        let number = value.prefix { $0.isNumber || $0 == "." }
        let suffix = value.dropFirst(number.count).uppercased()
        guard let parsed = Double(number), parsed >= 0 else { return nil }

        let multiplier: Double
        switch suffix {
        case "K": multiplier = 1_024
        case "M": multiplier = 1_048_576
        case "G": multiplier = 1_073_741_824
        case "T": multiplier = 1_099_511_627_776
        case "": multiplier = 1
        default: return nil
        }
        let bytes = parsed * multiplier
        guard bytes <= Double(UInt64.max) else { return nil }
        return UInt64(bytes.rounded())
    }
}

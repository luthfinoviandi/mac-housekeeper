import Foundation
import MacHousekeeperCore

@main
struct MacHousekeeper {
    static let appName = "MacHousekeeper"

    /// Parses one CLI invocation, executes supported read-only commands, and maps failures to exit status.
    static func main() {
        do {
            let command = try CLIParser().parse(Array(CommandLine.arguments.dropFirst()))

            switch command {
            case .help:
                print(CLIOutput.help)
            case .scanLargeFiles, .scanCaches, .scanApplications:
                guard let request = command.scanRequest else {
                    CLIOutput.writeError("The requested scan is unavailable.")
                    exit(EXIT_FAILURE)
                }
                let result = ScanCoordinator(
                    cacheLocations: ReviewedCacheCatalog.locations()
                ).scan(request: request) { progress in
                    guard progress.scannedItemCount > 0 else { return }
                    print(CLIOutput.render(progress))
                }
                print(CLIOutput.render(result))
                if result.findings.isEmpty, !result.warnings.isEmpty {
                    CLIOutput.writeError("Scan could not produce a usable result.")
                    exit(EXIT_FAILURE)
                }
            case .memory:
                print(CLIOutput.render(MemoryReporter().report()))
            case .cleanCaches:
                let cacheLocations = ReviewedCacheCatalog.locations()
                _ = CleanCommand(cacheLocations: cacheLocations).run()
                if cacheLocations.isEmpty {
                    CLIOutput.writeError("No reviewed cache locations are available; no files were changed.")
                    exit(EXIT_FAILURE)
                }
            }
        } catch let error as CLIParseError {
            CLIOutput.writeError(error.description)
            exit(EXIT_FAILURE)
        } catch {
            CLIOutput.writeError("Unexpected command error.")
            exit(EXIT_FAILURE)
        }
    }
}

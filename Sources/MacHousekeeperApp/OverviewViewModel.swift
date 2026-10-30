import Foundation
import MacHousekeeperCore

/// The data gathered together for the first read-only overview screen.
struct OverviewSnapshot: Equatable, Sendable {
    let cacheResult: ScanResult
    let memoryStatus: MemoryStatus
}

/// Owns overview loading state while keeping filesystem and process work off the main actor.
@MainActor
final class OverviewViewModel: ObservableObject {
    /// States rendered by the overview shell.
    enum State: Equatable {
        case idle
        case loading
        case loaded(OverviewSnapshot)
        case empty(OverviewSnapshot)
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    private let loadSnapshot: @Sendable () throws -> OverviewSnapshot

    /// Creates a view model with the production loader or an injected fixture loader for tests.
    /// - Parameter loadSnapshot: Synchronous core work to execute on a detached task.
    init(loadSnapshot: @escaping @Sendable () throws -> OverviewSnapshot = OverviewViewModel.makeSnapshot) {
        self.loadSnapshot = loadSnapshot
    }

    /// Starts one overview load and ignores repeated requests while work is already in flight.
    func load() {
        guard state != .loading else { return }
        state = .loading
        let loadSnapshot = self.loadSnapshot

        Task { [weak self] in
            do {
                let snapshot = try await Task.detached {
                    try loadSnapshot()
                }.value
                self?.state = snapshot.cacheResult.findings.isEmpty ? .empty(snapshot) : .loaded(snapshot)
            } catch {
                self?.state = .failed(error.localizedDescription)
            }
        }
    }

    /// Performs the cache scan and memory observation used by the production overview.
    /// - Returns: A read-only snapshot for the UI.
    private nonisolated static func makeSnapshot() -> OverviewSnapshot {
        let cacheLocations = ReviewedCacheCatalog.locations()
        let cacheResult = ScanCoordinator(cacheLocations: cacheLocations).scan(request: .scanCaches)
        return OverviewSnapshot(cacheResult: cacheResult, memoryStatus: MemoryReporter().report())
    }
}

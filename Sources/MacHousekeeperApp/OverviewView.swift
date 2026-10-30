import SwiftUI
import MacHousekeeperCore

/// Displays the read-only cache and memory overview without cleanup controls.
struct OverviewView: View {
    @StateObject private var viewModel = OverviewViewModel()

    var body: some View {
        NavigationSplitView {
            List {
                Label("Overview", systemImage: "gauge.with.dots.needle.67percent")
            }
            .navigationTitle("MacHousekeeper")
        } detail: {
            OverviewContent(state: viewModel.state)
                .frame(maxWidth: 760, alignment: .leading)
                .padding()
                .task {
                    viewModel.load()
                }
        }
    }
}

/// Renders every loading, error, empty, and loaded state exposed by the overview model.
private struct OverviewContent: View {
    let state: OverviewViewModel.State

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView("Inspecting reviewed caches and memory…")
        case let .failed(message):
            ContentUnavailableView(
                "Overview unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case let .empty(snapshot):
            VStack(alignment: .leading, spacing: 20) {
                CacheSummarySection(summary: snapshot.cacheResult.summary)
                ContentUnavailableView(
                    "No cache findings",
                    systemImage: "checkmark.circle",
                    description: Text("No reviewed cache items were found.")
                )
                MemorySection(status: snapshot.memoryStatus)
                WarningsSection(warnings: snapshot.cacheResult.warnings)
            }
        case let .loaded(snapshot):
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CacheSummarySection(summary: snapshot.cacheResult.summary)
                    MemorySection(status: snapshot.memoryStatus)
                    WarningsSection(warnings: snapshot.cacheResult.warnings)
                }
            }
        }
    }
}

/// Shows the read-only cache totals returned by the core scan.
private struct CacheSummarySection: View {
    let summary: ScanSummary

    var body: some View {
        GroupBox("Cache summary") {
            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
                GridRow { Text("Findings"); Text("\(summary.findingCount)") }
                GridRow { Text("Eligible"); Text("\(summary.eligibleCount)") }
                GridRow { Text("Estimated size"); Text(ByteCountFormatter.string(fromByteCount: Int64(clamping: summary.totalBytes), countStyle: .file)) }
                GridRow { Text("Potentially reclaimable"); Text(ByteCountFormatter.string(fromByteCount: Int64(clamping: summary.eligibleBytes), countStyle: .file)) }
            }
        }
    }
}

/// Shows the point-in-time memory observation and any unavailable indicators.
private struct MemorySection: View {
    let status: MemoryStatus

    var body: some View {
        GroupBox("Memory status") {
            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Physical memory", value: format(status.physicalMemoryBytes))
                LabeledContent("Available memory", value: format(status.availableMemoryBytes))
                LabeledContent("Swap used", value: format(status.swapUsedBytes))
                Text("Observed \(status.observedAt.formatted(date: .abbreviated, time: .shortened))")
                    .foregroundStyle(.secondary)
                if !status.limitations.isEmpty {
                    Divider()
                    Text("Limitations")
                        .font(.headline)
                    ForEach(status.limitations, id: \.self) { limitation in
                        Text(limitation)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    /// Formats an optional byte count without turning an unavailable indicator into zero.
    private func format(_ bytes: UInt64?) -> String {
        guard let bytes else { return "Unavailable" }
        return ByteCountFormatter.string(fromByteCount: Int64(clamping: bytes), countStyle: .file)
    }
}

/// Shows non-fatal scan limitations while preserving their associated locations.
private struct WarningsSection: View {
    let warnings: [ScanWarning]

    var body: some View {
        if !warnings.isEmpty {
            GroupBox("Warnings") {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(warnings.enumerated()), id: \.offset) { _, warning in
                        Text((warning.location.map { "\($0.path): " } ?? "") + warning.message)
                    }
                }
            }
        }
    }
}

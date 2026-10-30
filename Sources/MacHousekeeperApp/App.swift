import SwiftUI

/// Hosts the read-only SwiftUI shell for MacHousekeeper.
@main
struct MacHousekeeperApp: App {
    var body: some Scene {
        WindowGroup {
            OverviewView()
        }
    }
}

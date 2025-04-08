import SwiftUI
import SwiftData
import StoreKit

@main
struct SaveLoopeApp: App {
    @StateObject private var dateSelection = DateSelectionState()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dateSelection)
        }
        .modelContainer(for: [Envelope.self, TransactionRecord.self])
    }
}

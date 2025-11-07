import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var dateSelection: DateSelectionState

    var body: some View {
        TabView {
            Tab("봉투", systemImage: "envelope.fill") {
                HomeView()
                    .environmentObject(dateSelection)
            }

            Tab("캘린더", systemImage: "calendar") {
                CalendarView()
                    .environmentObject(dateSelection)
            }

            Tab("설정", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(DateSelectionState())
}

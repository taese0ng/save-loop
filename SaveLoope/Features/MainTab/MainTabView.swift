import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var dateSelection: DateSelectionState

    var body: some View {
        TabView {
            Tab("tab.home", systemImage: "envelope.fill") { // 홈
                HomeView()
                    .environmentObject(dateSelection)
            }

            Tab("tab.calendar", systemImage: "calendar") { // 캘린더
                CalendarView()
                    .environmentObject(dateSelection)
            }

            Tab("tab.settings", systemImage: "gearshape.fill") { // 설정
                SettingsView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(DateSelectionState())
}

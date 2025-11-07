import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .envelopes // 기본 선택된 탭
    @EnvironmentObject private var dateSelection: DateSelectionState

   enum Tab {
       case envelopes, calendar, more
   }

   var body: some View {
       VStack(spacing: 0) {
           Spacer()
           // 현재 선택된 탭에 따라 다른 화면 표시
           switch selectedTab {
               case .envelopes:
                   HomeView()
                       .environmentObject(dateSelection)
               case .calendar:
                   CalendarView()
                       .environmentObject(dateSelection)
               case .more:
                   SettingsView()
           }

           // 🔹 커스텀 탭바
           HStack {
               Spacer()

               // 🔹 홈 탭
               TabButton(icon: "house.fill", title: "홈", isSelected: selectedTab == .envelopes) {
                   selectedTab = .envelopes
               }

               Spacer()

               // 🔹 캘린더 탭
               TabButton(icon: "calendar", title: "캘린더", isSelected: selectedTab == .calendar) {
                   selectedTab = .calendar
               }

               Spacer()

               // 🔹 설정 탭
               TabButton(icon: "gearshape.fill", title: "설정", isSelected: selectedTab == .more) {
                   selectedTab = .more
               }

               Spacer()
           }
           .padding(.top, 12)
           .overlay( // 🔹 상단 1px Border 추가
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.3)),
                alignment: .top
            )
       }
   }
}

#Preview {
    MainTabView()
        .environmentObject(DateSelectionState())
}

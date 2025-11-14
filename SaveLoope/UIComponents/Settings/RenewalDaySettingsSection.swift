import SwiftUI

struct RenewalDaySettingsSection: View {
    @ObservedObject private var renewalDayManager = RenewalDayManager.shared
    @State private var showingRenewalDayPicker = false
    
    var body: some View {
        Button(action: {
            showingRenewalDayPicker = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.renewal_day".localized) // 봉투 갱신일
                        .foregroundColor(.primary)
                    
                    Text("settings.renewal_day.description".localized.replacingOccurrences(of: "{day}", with: "\(renewalDayManager.renewalDay)"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingRenewalDayPicker) {
            RenewalDayPickerView()
        }
        
    }
}

struct RenewalDayPickerView: View {
    @ObservedObject private var renewalDayManager = RenewalDayManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: Int
    
    init() {
        // 초기값을 현재 설정된 갱신일로 설정
        _selectedDay = State(initialValue: RenewalDayManager.shared.renewalDay)
    }
    
    var body: some View {
        StandardSheetContainer(
            title: "settings.renewal_day".localized // 봉투 갱신일
        ) {
            VStack(spacing: 0) {
                // Picker
                Picker("settings.renewal_day".localized, selection: $selectedDay) {
                    ForEach(1...31, id: \.self) { day in
                        Text("settings.renewal_day.day_format".localized.replacingOccurrences(of: "{day}", with: "\(day)"))
                            .tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 180)
                .padding(.top, 20)
                
                // 설명 텍스트
                Text("settings.renewal_day.footer".localized) // 매월 설정한 날짜에 봉투가 갱신됩니다. 예: 25일로 설정하면 매월 25일부터 새로운 주기가 시작됩니다.
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            }
        } footer: {
            // 완료 버튼
            Button(action: {
                // 완료 버튼을 눌렀을 때만 적용
                renewalDayManager.setRenewalDay(selectedDay)
                
                // 햅틱 피드백
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                
                dismiss()
            }) {
                Text("common.done".localized) // 완료
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
        .presentationDetents([.height(460)])
    }
}


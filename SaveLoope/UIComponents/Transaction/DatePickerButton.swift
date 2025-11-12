import SwiftUI

struct DatePickerButton: View {
    let label: String
    @Binding var date: Date
    @Binding var showingDatePicker: Bool
    let selectedDate: Date
    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = localizationManager.getCurrentLocale() // 현재 선택된 언어에 맞는 locale 설정
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color("PrimaryText"))

            Button(action: {
                showingDatePicker = true
            }) {
                HStack {
                    Text(dateFormatter.string(from: date))
                        .foregroundColor(Color("PrimaryText"))
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundColor(Color("SecondaryText"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingDatePicker) {
                MonthCalendarView(selectedDate: selectedDate, date: $date)
                    .presentationDetents([.height(400)])
                    .presentationDragIndicator(.visible)
                    .onChange(of: date) { oldValue, newValue in
                        showingDatePicker = false
                    }
            }
        }
    }
}

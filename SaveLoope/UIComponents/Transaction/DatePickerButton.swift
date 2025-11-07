import SwiftUI

struct DatePickerButton: View {
    let label: String
    @Binding var date: Date
    @Binding var showingDatePicker: Bool
    let selectedDate: Date

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 16))

            Button(action: {
                showingDatePicker = true
            }) {
                HStack {
                    Text(dateFormatter.string(from: date))
                        .foregroundColor(.black)
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
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

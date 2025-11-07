import SwiftUI

struct TransactionTypePicker: View {
    let label: String
    @Binding var selectedType: TransactionType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 16))

            Picker(label, selection: $selectedType) {
                Text("수입").tag(TransactionType.income)
                Text("지출").tag(TransactionType.expense)
            }
            .pickerStyle(.segmented)
        }
    }
}

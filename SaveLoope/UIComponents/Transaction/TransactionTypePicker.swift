import SwiftUI

struct TransactionTypePicker: View {
    let label: String
    @Binding var selectedType: TransactionType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color("PrimaryText"))

            Picker(label, selection: $selectedType) {
                Text("transaction.type.income".localized).tag(TransactionType.income) // 수입
                Text("transaction.type.expense".localized).tag(TransactionType.expense) // 지출
            }
            .pickerStyle(.segmented)
        }
    }
}

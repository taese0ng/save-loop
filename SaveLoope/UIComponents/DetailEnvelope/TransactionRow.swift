import SwiftUI
import SwiftData

struct TransactionRow: View {
    let transaction: TransactionRecord
    @State private var showingActionSheet: Bool = false
    var onClickMenu: (() -> Void)? = nil
    
    private let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack{
                    Text(dateFormatter.string(from: transaction.date))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if transaction.parentId != nil {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
            
            Text("\(transaction.type == .income ? "+" : "-")\(transaction.amount.formattedWithSeparator)원")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(transaction.type == .income ? .blue : .red)
            
            Spacer().frame(width: 10)
            
            Button(action: {
                onClickMenu!()
            }) {
                VStack(spacing: 3) {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 4, height: 4)
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 4, height: 4)
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 4, height: 4)
                }
                .frame(width: 24, height: 24)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    let transaction = TransactionRecord(amount:3000, date: Date(), type: .expense, note:"", isRecurring:false)
    TransactionRow(transaction: transaction, onClickMenu:{})
}

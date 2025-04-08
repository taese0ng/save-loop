import Foundation
import SwiftData

enum TransactionType: String, Codable {
    case income = "INCOME"
    case expense = "EXPENSE"
}

@Model
final class TransactionRecord {
    var id: UUID
    var amount: Int
    var date: Date
    var type: TransactionType
    var envelope: Envelope?
    var note: String
    var isRecurring: Bool
    var parentId: UUID?
    
    init(amount: Int, date: Date, type: TransactionType, envelope: Envelope? = nil, note: String = "", isRecurring: Bool = false, parentId: UUID? = nil) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.type = type
        self.envelope = envelope
        self.note = note
        self.isRecurring = isRecurring
        self.parentId = parentId
    }
}

import SwiftData
import Foundation

enum EnvelopeType: String, Codable {
    case normal = "normal"           // 일반 봉투 (현재 월만)
    case recurring = "recurring"     // 반복 봉투 (매달 초기화)
    case persistent = "persistent"   // 지속형 봉투 (계속 유지)
}

@Model
final class Envelope: Hashable {
    var id: UUID
    var name: String
    var budget: Double
    var income: Double
    var spent: Double
    var goal: Double
    var createdAt: Date
    var isRecurring: Bool
    var parentId: UUID?
    var envelopeType: String = EnvelopeType.normal.rawValue
    var sortOrder: Int = 0

    init(name: String, budget: Double, income: Double = 0, spent: Double = 0, goal: Double = 0, isRecurring: Bool = false, parentId: UUID? = nil, envelopeType: EnvelopeType = .normal) {
        self.id = UUID()
        self.name = name
        self.budget = budget
        self.income = income
        self.spent = spent
        self.goal = goal
        self.createdAt = Date()
        self.isRecurring = isRecurring
        self.parentId = parentId
        self.envelopeType = envelopeType.rawValue
    }

    var type: EnvelopeType {
        get {
            return EnvelopeType(rawValue: envelopeType) ?? .normal
        }
        set {
            envelopeType = newValue.rawValue
            isRecurring = (newValue == .recurring)
        }
    }
    
    var remaining: Double {
        budget + income - spent
    }
    
    var progress: Double {
        if budget > 0 {
            let progress: Double = remaining / budget
            return progress > 1 ? 1.0 : progress
        } else {
            return 0.0
        }
    }
    
    var year: Int {
        Calendar.current.component(.year, from: createdAt)
    }
    
    var month: Int {
        Calendar.current.component(.month, from: createdAt)
    }
    
    static func == (lhs: Envelope, rhs: Envelope) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

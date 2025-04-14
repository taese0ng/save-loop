import SwiftData
import Foundation

@Model
final class Envelope: Hashable {
    var id: UUID
    var name: String
    var budget: Int
    var income: Int
    var spent: Int
    var goal: Int
    var createdAt: Date
    var isRecurring: Bool
    var parentId: UUID?
    
    init(name: String, budget: Int, income: Int = 0, spent: Int = 0, goal: Int = 0, isRecurring: Bool = false, parentId: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.budget = budget
        self.income = income
        self.spent = spent
        self.goal = goal
        self.createdAt = Date()
        self.isRecurring = isRecurring
        self.parentId = parentId
    }
    
    var remaining: Int {
        budget + income - spent
    }
    
    var progress: Double {
        if budget > 0 {
            let progress: Double = Double(remaining) / Double(budget)   
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

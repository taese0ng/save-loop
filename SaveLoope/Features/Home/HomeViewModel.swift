import SwiftUI
import SwiftData
import Foundation

class HomeViewModel: ObservableObject {
    /// 전체 남은 예산 합계 계산
    func totalRemaining(from envelopes: [Envelope]) -> Int {
        envelopes.reduce(0) { $0 + $1.remaining }
    }
    
    /// 반복 생성이 필요한 봉투들을 확인하고 생성
    func checkAndCreateRecurringEnvelopes(using context: ModelContext) {
        let calendar: Calendar = Calendar.current
        let currentDate: Date = Date()
        let currentYear: Int = calendar.component(.year, from: currentDate)
        let currentMonth: Int = calendar.component(.month, from: currentDate)

        let previousMonthDate: Date = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        let previousYear: Int = calendar.component(.year, from: previousMonthDate)
        let previousMonth: Int = calendar.component(.month, from: previousMonthDate)
        
        // 모든 봉투를 가져옴
        let envelopeDescriptor = FetchDescriptor<Envelope>()
        do {
            let allEnvelopes = try context.fetch(envelopeDescriptor)
            
            // 반복 생성이 필요한 봉투들만 필터링
            let recurringEnvelopes = allEnvelopes.filter { $0.isRecurring && calendar.component(.month, from: $0.createdAt) == previousMonth && calendar.component(.year, from: $0.createdAt) == previousYear }
            let currentEnvelopes = allEnvelopes.filter { calendar.component(.month, from: $0.createdAt) == currentMonth && calendar.component(.year, from: $0.createdAt) == currentYear }
            
            for envelope in recurringEnvelopes {
                // 이미 현재 월에 생성된 봉투가 있는지 확인
                let existingEnvelope = currentEnvelopes.first { existing in
                    existing.parentId == envelope.id &&
                    calendar.component(.year, from: existing.createdAt) == currentYear &&
                    calendar.component(.month, from: existing.createdAt) == currentMonth
                }
                
                // 현재 월에 해당하는 봉투가 없으면 생성
                if existingEnvelope == nil {
                    let newEnvelope = Envelope(
                        name: envelope.name,
                        budget: envelope.budget,
                        income: 0,
                        spent: 0,
                        goal: envelope.goal,
                        isRecurring: true,
                        parentId: envelope.id
                    )
                    context.insert(newEnvelope)
                }
            }
            
            // 생성된 반복 봉투들이 있으면 해당 거래내역도 생성
            checkAndCreateRecurringTransactions(using: context)
        } catch {
            print("봉투 데이터를 가져오는데 실패했습니다: \(error)")
            // TODO: 에러 처리 로직 추가 (예: 사용자에게 알림 표시)
        }
    }
    
    /// 반복 생성이 필요한 거래 내역들을 확인하고 생성
    func checkAndCreateRecurringTransactions(using context: ModelContext) {
        let calendar: Calendar = Calendar.current
        let currentDate: Date = Date()
        let currentYear: Int = calendar.component(.year, from: currentDate)
        let currentMonth: Int = calendar.component(.month, from: currentDate)

        let previousMonthDate: Date = calendar.date(byAdding: .month, value: -1, to: currentDate)!
        let previousYear: Int = calendar.component(.year, from: previousMonthDate)
        let previousMonth: Int = calendar.component(.month, from: previousMonthDate)
        
        // 모든 Envelope와 TransactionRecord를 가져옴
        let envelopeDescriptor = FetchDescriptor<Envelope>()
        let transactionDescriptor = FetchDescriptor<TransactionRecord>()
        
        do {
            let allEnvelopes = try context.fetch(envelopeDescriptor)
            let allTransactions = try context.fetch(transactionDescriptor)
            
            // 이전 달의 반복 거래 내역 필터링
            let recurringTransactions = allTransactions.filter { transaction in
                transaction.isRecurring && 
                calendar.component(.month, from: transaction.date) == previousMonth && 
                calendar.component(.year, from: transaction.date) == previousYear
            }
            
            // 현재 달에 이미 생성된 거래 내역 필터링
            let currentTransactions = allTransactions.filter { transaction in
                calendar.component(.month, from: transaction.date) == currentMonth && 
                calendar.component(.year, from: transaction.date) == currentYear
            }
            
            // 현재 달의 봉투 필터링
            let currentEnvelopes = allEnvelopes.filter { envelope in
                calendar.component(.month, from: envelope.createdAt) == currentMonth && 
                calendar.component(.year, from: envelope.createdAt) == currentYear
            }
            
            for transaction in recurringTransactions {
                // 이미 현재 월에 생성된 거래 내역이 있는지 확인
                let existingTransaction = currentTransactions.first { existing in
                    existing.parentId == transaction.id &&
                    calendar.component(.year, from: existing.date) == currentYear &&
                    calendar.component(.month, from: existing.date) == currentMonth
                }
                
                // 현재 월에 해당하는 거래 내역이 없으면 생성
                if existingTransaction == nil {
                    // 해당 거래에 연결된 봉투가 있는 경우, 현재 달의 해당하는 봉투 찾기
                    var matchingCurrentEnvelope: Envelope? = nil
                    
                    if let oldEnvelope = transaction.envelope {
                        // parentId를 기반으로 현재 달의 봉투 찾기
                        matchingCurrentEnvelope = currentEnvelopes.first { envelope in
                            envelope.parentId == oldEnvelope.id
                        }
                        
                        // parentId가 없는 경우 봉투 이름으로 매칭 시도
                        if matchingCurrentEnvelope == nil {
                            matchingCurrentEnvelope = currentEnvelopes.first { envelope in
                                envelope.name == oldEnvelope.name
                            }
                        }
                        
                        // 매칭되는 봉투가 없으면 이 거래 내역은 생성하지 않고 다음으로 넘어감
                        if matchingCurrentEnvelope == nil {
                            continue
                        }
                    } else {
                        // 기존 트랜잭션에 연결된 봉투가 없으면 새 트랜잭션도 생성하지 않음
                        continue
                    }
                    
                    // 현재 날짜의 동일한 일자로 설정
                    let dayComponent = calendar.component(.day, from: transaction.date)
                    var newDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: dayComponent)) ?? currentDate
                    
                    // 월말 처리 (예: 30일이 없는 2월 등)
                    if calendar.component(.month, from: newDate) != currentMonth {
                        let range: Range<Int> = calendar.range(of: .day, in: .month, for: Date(timeIntervalSince1970: 0))!
                        let lastDay: Int = range.count
                        newDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: lastDay))!
                    }
                    
                    // 새 거래 내역 생성
                    let newTransaction = TransactionRecord(
                        amount: transaction.amount,
                        date: newDate,
                        type: transaction.type,
                        envelope: matchingCurrentEnvelope,
                        note: transaction.note,
                        isRecurring: true,
                        parentId: transaction.id
                    )
                    
                    context.insert(newTransaction)
                    
                    // 매칭된 봉투가 있는 경우 금액 업데이트
                    if let envelope = matchingCurrentEnvelope {
                        if transaction.type == .income {
                            envelope.income += transaction.amount
                        } else if transaction.type == .expense {
                            envelope.spent += transaction.amount
                        }
                    }
                }
            }
        } catch {
            print("거래 내역 데이터를 처리하는데 실패했습니다: \(error)")
            // TODO: 에러 처리 로직 추가 (예: 사용자에게 알림 표시)
        }
    }
    
    /// 샘플 Envelope 하나 추가 (테스트 용도)
    func addSampleEnvelope(using context: ModelContext) {
        let sample = Envelope(name: "새 봉투", budget: 100000)
        context.insert(sample)
    }
}

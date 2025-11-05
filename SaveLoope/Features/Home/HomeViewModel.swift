import SwiftUI
import SwiftData
import Foundation

@MainActor
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
            
            // 반복 생성이 설정된 모든 봉투 찾기 (parentId가 자기 자신인 것들)
            let originalRecurringEnvelopes = allEnvelopes.filter { $0.isRecurring && $0.parentId == $0.id }
            
            // 현재 월의 봉투들
            let currentEnvelopes = allEnvelopes.filter { 
                calendar.component(.month, from: $0.createdAt) == currentMonth && 
                calendar.component(.year, from: $0.createdAt) == currentYear 
            }
            
            for originalEnvelope in originalRecurringEnvelopes {
                // 이미 현재 월에 생성된 봉투가 있는지 확인
                let existingEnvelope = currentEnvelopes.first { existing in
                    (existing.parentId == originalEnvelope.id || existing.id == originalEnvelope.id) &&
                    calendar.component(.year, from: existing.createdAt) == currentYear &&
                    calendar.component(.month, from: existing.createdAt) == currentMonth
                }
                
                // 현재 월에 해당하는 봉투가 없으면 생성
                if existingEnvelope == nil {
                    let newEnvelope = Envelope(
                        name: originalEnvelope.name,
                        budget: originalEnvelope.budget,
                        income: 0,
                        spent: 0,
                        goal: originalEnvelope.goal,
                        isRecurring: true,
                        parentId: originalEnvelope.id
                    )
                    context.insert(newEnvelope)
                }
            }
            
            // 생성된 반복 봉투들이 있으면 해당 거래내역도 생성
            checkAndCreateRecurringTransactions(using: context)
            
            // 명시적으로 저장 (아이클라우드 동기화 포함)
            do {
                try context.save()
                print("✅ 반복 봉투 생성 완료 (아이클라우드 동기화 시작)")
            } catch {
                print("❌ 반복 봉투 저장 실패: \(error.localizedDescription)")
            }
        } catch {
            print("봉투 데이터를 가져오는데 실패했습니다: \(error)")
        }
    }
    
    /// 반복 생성이 필요한 거래 내역들을 확인하고 생성
    func checkAndCreateRecurringTransactions(using context: ModelContext) {
        let calendar: Calendar = Calendar.current
        let currentDate: Date = Date()
        let currentYear: Int = calendar.component(.year, from: currentDate)
        let currentMonth: Int = calendar.component(.month, from: currentDate)
        
        // 모든 Envelope와 TransactionRecord를 가져옴
        let envelopeDescriptor = FetchDescriptor<Envelope>()
        let transactionDescriptor = FetchDescriptor<TransactionRecord>()
        
        do {
            let allEnvelopes = try context.fetch(envelopeDescriptor)
            let allTransactions = try context.fetch(transactionDescriptor)
            
            // 반복 생성이 설정된 원본 거래 내역 (parentId가 자기 자신인 것들)
            let originalRecurringTransactions = allTransactions.filter { 
                $0.isRecurring && $0.parentId == $0.id
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
            
            for originalTransaction in originalRecurringTransactions {
                // 이미 현재 월에 생성된 거래 내역이 있는지 확인
                let existingTransaction = currentTransactions.first { existing in
                    (existing.parentId == originalTransaction.id || existing.id == originalTransaction.id) &&
                    calendar.component(.year, from: existing.date) == currentYear &&
                    calendar.component(.month, from: existing.date) == currentMonth
                }
                
                // 현재 월에 해당하는 거래 내역이 없으면 생성
                if existingTransaction == nil {
                    // 해당 거래에 연결된 봉투가 있는 경우, 현재 달의 해당하는 봉투 찾기
                    var matchingCurrentEnvelope: Envelope? = nil
                    
                    if let oldEnvelope = originalTransaction.envelope {
                        // parentId를 기반으로 현재 달의 봉투 찾기
                        let originalEnvelopeId = oldEnvelope.parentId ?? oldEnvelope.id
                        matchingCurrentEnvelope = currentEnvelopes.first { envelope in
                            envelope.id == originalEnvelopeId || envelope.parentId == originalEnvelopeId
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
                    let dayComponent = calendar.component(.day, from: originalTransaction.date)
                    var newDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: dayComponent)) ?? currentDate
                    
                    // 월말 처리 (예: 30일이 없는 2월 등) - 수정된 로직
                    if calendar.component(.month, from: newDate) != currentMonth {
                        // 현재 월의 마지막 날 계산
                        if let range = calendar.range(of: .day, in: .month, for: currentDate) {
                            let lastDay: Int = range.upperBound - 1
                            newDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: lastDay)) ?? currentDate
                        }
                    }
                    
                    // 새 거래 내역 생성
                    let newTransaction = TransactionRecord(
                        amount: originalTransaction.amount,
                        date: newDate,
                        type: originalTransaction.type,
                        envelope: matchingCurrentEnvelope,
                        note: originalTransaction.note,
                        isRecurring: true,
                        parentId: originalTransaction.id
                    )
                    
                    context.insert(newTransaction)
                    
                    // 매칭된 봉투가 있는 경우 금액 업데이트
                    if let envelope = matchingCurrentEnvelope {
                        if originalTransaction.type == .income {
                            envelope.income += originalTransaction.amount
                        } else if originalTransaction.type == .expense {
                            envelope.spent += originalTransaction.amount
                        }
                    }
                }
            }
            
            // 명시적으로 저장 (아이클라우드 동기화 포함)
            do {
                try context.save()
                print("✅ 반복 거래 내역 생성 완료 (아이클라우드 동기화 시작)")
            } catch {
                print("❌ 반복 거래 내역 저장 실패: \(error.localizedDescription)")
            }
        } catch {
            print("거래 내역 데이터를 처리하는데 실패했습니다: \(error)")
        }
    }
    
    /// 샘플 Envelope 하나 추가 (테스트 용도)
    func addSampleEnvelope(using context: ModelContext) {
        let sample = Envelope(name: "새 봉투", budget: 100000)
        context.insert(sample)
    }
}

import SwiftUI
import SwiftData
import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    /// 전체 남은 예산 합계 계산
    func totalRemaining(from envelopes: [Envelope]) -> Double {
        envelopes.reduce(0) { $0 + $1.remaining }
    }
    
    /// 반복 생성이 필요한 봉투들을 확인하고 생성
    func checkAndCreateRecurringEnvelopes(using context: ModelContext) {
        let calendar = Calendar.current
        let currentDate = Date()
        let renewalDayManager = RenewalDayManager.shared
        
        // 현재 날짜가 속한 갱신 주기 계산
        let currentCycle = renewalDayManager.getRenewalCycle(for: currentDate)
        guard let cycleStartDate = calendar.date(from: DateComponents(year: currentCycle.year, month: currentCycle.month, day: renewalDayManager.renewalDay)) else {
            print("❌ 갱신 주기 시작일 계산 실패")
            return
        }
        
        // 모든 봉투를 가져옴
        let envelopeDescriptor = FetchDescriptor<Envelope>()
        do {
            let allEnvelopes = try context.fetch(envelopeDescriptor)
            
            // 반복 생성이 설정된 모든 봉투 찾기 (parentId가 자기 자신인 것들)
            // 지속형 봉투는 제외
            let originalRecurringEnvelopes = allEnvelopes.filter {
                $0.isRecurring &&
                $0.parentId == $0.id &&
                $0.type == .recurring
            }
            
            // 현재 갱신 주기의 봉투들 (갱신일 기준)
            let currentCycleEnvelopes = allEnvelopes.filter { envelope in
                // 지속형 봉투는 제외
                if envelope.type == .persistent {
                    return false
                }
                // 봉투의 갱신 주기 계산
                let envelopeCycle = renewalDayManager.getRenewalCycle(for: envelope.createdAt)
                return envelopeCycle.year == currentCycle.year && envelopeCycle.month == currentCycle.month
            }
            
            for originalEnvelope in originalRecurringEnvelopes {
                // 이미 현재 갱신 주기에 생성된 봉투가 있는지 확인
                let existingEnvelope = currentCycleEnvelopes.first { existing in
                    existing.parentId == originalEnvelope.id || existing.id == originalEnvelope.id
                }
                
                // 현재 갱신 주기에 해당하는 봉투가 없으면 생성
                if existingEnvelope == nil {
                    let newEnvelope = Envelope(
                        name: originalEnvelope.name,
                        budget: originalEnvelope.budget,
                        income: 0,
                        spent: 0,
                        goal: originalEnvelope.goal,
                        isRecurring: true,
                        parentId: originalEnvelope.id,
                        envelopeType: .recurring
                    )
                    // 갱신 주기 시작일로 createdAt 설정
                    newEnvelope.createdAt = cycleStartDate
                    // 원본 봉투의 sortOrder 상속
                    newEnvelope.sortOrder = originalEnvelope.sortOrder
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
        let calendar = Calendar.current
        let currentDate = Date()
        let renewalDayManager = RenewalDayManager.shared
        
        // 현재 날짜가 속한 갱신 주기 계산
        let currentCycle = renewalDayManager.getRenewalCycle(for: currentDate)
        
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
            
            // 현재 갱신 주기에 이미 생성된 거래 내역 필터링
            let currentCycleTransactions = allTransactions.filter { transaction in
                let transactionCycle = renewalDayManager.getRenewalCycle(for: transaction.date)
                return transactionCycle.year == currentCycle.year && transactionCycle.month == currentCycle.month
            }
            
            // 현재 갱신 주기의 봉투 필터링
            let currentCycleEnvelopes = allEnvelopes.filter { envelope in
                // 지속형 봉투는 제외
                if envelope.type == .persistent {
                    return false
                }
                let envelopeCycle = renewalDayManager.getRenewalCycle(for: envelope.createdAt)
                return envelopeCycle.year == currentCycle.year && envelopeCycle.month == currentCycle.month
            }
            
            for originalTransaction in originalRecurringTransactions {
                // 이미 현재 갱신 주기에 생성된 거래 내역이 있는지 확인
                let existingTransaction = currentCycleTransactions.first { existing in
                    existing.parentId == originalTransaction.id || existing.id == originalTransaction.id
                }
                
                // 현재 갱신 주기에 해당하는 거래 내역이 없으면 생성
                if existingTransaction == nil {
                    // 해당 거래에 연결된 봉투가 있는 경우, 현재 갱신 주기의 해당하는 봉투 찾기
                    var matchingCurrentEnvelope: Envelope? = nil
                    
                    if let oldEnvelope = originalTransaction.envelope {
                        // parentId를 기반으로 현재 갱신 주기의 봉투 찾기
                        let originalEnvelopeId = oldEnvelope.parentId ?? oldEnvelope.id
                        matchingCurrentEnvelope = currentCycleEnvelopes.first { envelope in
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
                    
                    // 원본 거래의 일자 계산 (갱신 주기 내에서의 상대 일자)
                    let originalDay = calendar.component(.day, from: originalTransaction.date)
                    let originalCycle = renewalDayManager.getRenewalCycle(for: originalTransaction.date)
                    
                    // 현재 갱신 주기 시작일 계산
                    guard let cycleStartDate = calendar.date(from: DateComponents(year: currentCycle.year, month: currentCycle.month, day: renewalDayManager.renewalDay)) else {
                        continue
                    }
                    
                    // 원본 거래가 원래 갱신 주기에서 몇 일째인지 계산
                    let daysFromCycleStart: Int
                    if originalDay >= renewalDayManager.renewalDay {
                        // 갱신일 이후
                        daysFromCycleStart = originalDay - renewalDayManager.renewalDay
                    } else {
                        // 갱신일 이전 (이전 달의 마지막 부분)
                        // 이전 달의 마지막 날짜 계산
                        if let prevMonth = calendar.date(byAdding: .month, value: -1, to: calendar.date(from: DateComponents(year: originalCycle.year, month: originalCycle.month, day: 1))!) {
                            let daysInPrevMonth = calendar.range(of: .day, in: .month, for: prevMonth)?.count ?? 30
                            daysFromCycleStart = (daysInPrevMonth - renewalDayManager.renewalDay + 1) + originalDay
                        } else {
                            daysFromCycleStart = originalDay
                        }
                    }
                    
                    // 현재 갱신 주기에서 동일한 상대 일자 계산
                    var newDate = calendar.date(byAdding: .day, value: daysFromCycleStart, to: cycleStartDate) ?? currentDate
                    
                    // 월말 처리 (예: 30일이 없는 2월 등)
                    let newDateCycle = renewalDayManager.getRenewalCycle(for: newDate)
                    if newDateCycle.year != currentCycle.year || newDateCycle.month != currentCycle.month {
                        // 현재 갱신 주기의 마지막 날 계산
                        if let nextCycleStart = calendar.date(byAdding: .month, value: 1, to: cycleStartDate) {
                            newDate = calendar.date(byAdding: .day, value: -1, to: nextCycleStart) ?? currentDate
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
}

import SwiftUI
import SwiftData

@MainActor
class SettingsViewModel: ObservableObject {
    /// 모든 데이터(봉투와 거래 기록)를 초기화하는 함수
    func resetAllData(context: ModelContext) {
        // 모든 Envelope 삭제
        let envelopeDescriptor = FetchDescriptor<Envelope>()
        do {
            let allEnvelopes = try context.fetch(envelopeDescriptor)
            for envelope in allEnvelopes {
                context.delete(envelope)
            }
        } catch {
            print("❌ Envelope 삭제 실패: \(error.localizedDescription)")
        }
        
        // 모든 TransactionRecord 삭제
        let transactionDescriptor = FetchDescriptor<TransactionRecord>()
        do {
            let allTransactions = try context.fetch(transactionDescriptor)
            for transaction in allTransactions {
                context.delete(transaction)
            }
        } catch {
            print("❌ TransactionRecord 삭제 실패: \(error.localizedDescription)")
        }
        
        // 명시적으로 저장 (아이클라우드 동기화 포함)
        do {
            try context.save()
            print("✅ 데이터 초기화 완료 (아이클라우드 동기화 시작)")
        } catch {
            print("❌ 데이터 초기화 저장 실패: \(error.localizedDescription)")
        }
    }
}

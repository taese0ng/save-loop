import SwiftUI
import SwiftData

// 모델 클래스 import
@preconcurrency import SwiftData

class SettingsViewModel: ObservableObject {
    
    /// 모든 데이터(봉투와 거래 기록)를 초기화하는 함수
    func resetAllData(context: ModelContext) {
        // 1. 모든 TransactionRecord 삭제
        do {
            let descriptor = FetchDescriptor<TransactionRecord>()
            let records = try context.fetch(descriptor)
            for record in records {
                context.delete(record)
            }
        } catch {
            print("거래 기록 삭제 중 오류 발생: \(error)")
        }
        
        // 2. 모든 Envelope 삭제
        do {
            let descriptor = FetchDescriptor<Envelope>()
            let envelopes = try context.fetch(descriptor)
            for envelope in envelopes {
                context.delete(envelope)
            }
        } catch {
            print("봉투 삭제 중 오류 발생: \(error)")
        }

         do {
            try context.save()
            print("데이터 초기화가 완료되었습니다.")
        } catch {
            print("데이터 저장 중 오류 발생: \(error)")
        }
    }
}

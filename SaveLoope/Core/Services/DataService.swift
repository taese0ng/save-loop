import SwiftData

struct DataService {
    /// 새로운 Envelope 생성 및 저장
    static func addEnvelope(name: String, budget: Int, context: ModelContext) {
        guard !name.isEmpty else { return }
        let newEnvelope = Envelope(name: name, budget: budget)
        context.insert(newEnvelope)
        // SwiftData는 기본적으로 상태 변경 시 자동 저장됩니다.
        // 필요한 경우 명시적으로 저장을 트리거할 수도 있습니다.
    }
    
    /// 기존 Envelope 삭제
    static func deleteEnvelope(_ envelope: Envelope, context: ModelContext) {
        context.delete(envelope)
    }
    
    // 추후에 복잡한 쿼리나 데이터 가져오기 등의 기능을 추가 가능
}

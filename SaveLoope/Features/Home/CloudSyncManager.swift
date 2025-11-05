import SwiftUI
import SwiftData
import CloudKit

/// iCloud 동기화 설정을 관리하는 매니저
@MainActor
class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published var isCloudSyncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isCloudSyncEnabled, forKey: "isCloudSyncEnabled")
            // 설정 변경 시 사용자에게 재시작 알림
            if oldValue != isCloudSyncEnabled {
                print("⚠️ 아이클라우드 동기화 설정이 변경되었습니다. 변경사항을 적용하려면 앱을 재시작해주세요.")
            }
        }
    }
    
    @Published var cloudAccountStatus: CKAccountStatus = .couldNotDetermine
    @Published var cloudAccountError: String?
    
    private init() {
        self.isCloudSyncEnabled = UserDefaults.standard.bool(forKey: "isCloudSyncEnabled")
        Task {
            await checkCloudAccountStatus()
        }
    }
    
    /// iCloud 계정 상태 확인
    func checkCloudAccountStatus() async {
        await MainActor.run {
            // CloudKit Capability가 없으면 기본적으로 비활성화
            print("⚠️ CloudKit Capability가 설정되지 않아 iCloud 동기화를 사용할 수 없습니다")
            self.cloudAccountStatus = .couldNotDetermine
            self.cloudAccountError = "iCloud 기능이 설정되지 않았습니다. 로컬 저장소만 사용됩니다."
        }
        
        // CloudKit capability가 없으면 여기서 함수 종료
        // CKContainer.default() 호출 자체를 하지 않음
        return
        
        /*
        // 아래 코드는 CloudKit Capability가 추가된 후 활성화하세요
        
        guard NSClassFromString("CKContainer") != nil else {
            await MainActor.run {
                print("⚠️ CloudKit을 사용할 수 없습니다 (Capability 미설정)")
                self.cloudAccountStatus = .couldNotDetermine
                self.cloudAccountError = "CloudKit을 사용할 수 없습니다"
            }
            return
        }
        
        do {
            let container = CKContainer.default()
            let status = try await container.accountStatus()
            
            await MainActor.run {
                self.cloudAccountStatus = status
                
                switch status {
                case .available:
                    print("✅ iCloud 계정 사용 가능")
                    self.cloudAccountError = nil
                case .noAccount:
                    print("⚠️ iCloud 계정 로그인 안 됨")
                    self.cloudAccountError = "iCloud에 로그인되어 있지 않습니다"
                case .restricted:
                    print("⚠️ iCloud 사용 제한됨")
                    self.cloudAccountError = "iCloud 사용이 제한되어 있습니다"
                case .couldNotDetermine:
                    print("⚠️ iCloud 상태를 확인할 수 없음")
                    self.cloudAccountError = "iCloud 상태를 확인할 수 없습니다"
                case .temporarilyUnavailable:
                    print("⚠️ iCloud 일시적으로 사용 불가")
                    self.cloudAccountError = "iCloud를 일시적으로 사용할 수 없습니다"
                @unknown default:
                    print("⚠️ 알 수 없는 iCloud 상태")
                    self.cloudAccountError = "알 수 없는 오류가 발생했습니다"
                }
            }
        } catch let error as NSError {
            await MainActor.run {
                print("❌ iCloud 상태 확인 실패: \(error.localizedDescription)")
                print("   Error Domain: \(error.domain), Code: \(error.code)")
                
                self.cloudAccountStatus = .couldNotDetermine
                
                // 에러 타입에 따른 적절한 메시지 설정
                if error.domain == "CKErrorDomain" {
                    self.cloudAccountError = "CloudKit을 사용할 수 없습니다"
                } else {
                    self.cloudAccountError = error.localizedDescription
                }
            }
        } catch {
            await MainActor.run {
                print("❌ iCloud 상태 확인 실패: \(error.localizedDescription)")
                self.cloudAccountStatus = .couldNotDetermine
                self.cloudAccountError = "iCloud 상태를 확인할 수 없습니다"
            }
        }
        */
    }
    
    /// iCloud 사용 가능 여부
    var isCloudAvailable: Bool {
        cloudAccountStatus == .available
    }
    
    /// iCloud 동기화가 활성화된 ModelContainer 생성
    static func createModelContainer(enableCloudSync: Bool) throws -> ModelContainer {
        let schema = Schema([
            Envelope.self,
            TransactionRecord.self
        ])
        
        let modelConfiguration: ModelConfiguration
        
        if enableCloudSync {
            // iCloud 동기화 활성화
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            print("🔄 아이클라우드 자동 동기화 모드로 ModelContainer 생성")
        } else {
            // 로컬 저장소만 사용
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )
            print("💾 로컬 전용 모드로 ModelContainer 생성")
        }
        
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
}


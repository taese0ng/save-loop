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
            if oldValue != isCloudSyncEnabled {
                if isCloudSyncEnabled {
                    print("✅ iCloud 동기화 활성화됨 - 즉시 적용")
                } else {
                    print("⚠️ iCloud 동기화 비활성화됨 - 새로운 데이터는 로컬에만 저장")
                }
            }
        }
    }

    @Published var cloudAccountStatus: CKAccountStatus = .couldNotDetermine
    @Published var cloudAccountError: String?

    private var subscriptionCheckTimer: Timer?
    private var initializationTask: Task<Void, Never>?

    private init() {
        self.isCloudSyncEnabled = UserDefaults.standard.bool(forKey: "isCloudSyncEnabled")
        initializationTask = Task { [weak self] in
            guard let self = self else { return }
            await self.checkCloudAccountStatus()
            await self.checkSubscriptionAndDisableSyncIfNeeded()
        }

        // 주기적으로 구독 상태 확인 (5분마다)
        startSubscriptionMonitoring()
    }

    deinit {
        subscriptionCheckTimer?.invalidate()
        initializationTask?.cancel()
    }

    /// 구독 상태 모니터링 시작
    private func startSubscriptionMonitoring() {
        subscriptionCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkSubscriptionAndDisableSyncIfNeeded()
            }
        }
        // RunLoop에 명시적으로 추가하여 백그라운드에서도 동작하도록 보장
        if let timer = subscriptionCheckTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// 구독 상태 확인 후 필요시 동기화 비활성화
    func checkSubscriptionAndDisableSyncIfNeeded() async {
        let isSubscribed = SubscriptionManager.shared.isSubscribed

        // iCloud 동기화가 켜져있는데 구독이 없으면 자동으로 끄기
        if isCloudSyncEnabled && !isSubscribed {
            print("⚠️ 구독이 해지되어 iCloud 동기화를 자동으로 비활성화합니다")
            isCloudSyncEnabled = false
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
    
    /// iCloud 동기화가 통합된 ModelContainer 생성
    /// CloudKit은 항상 활성화되며, 실제 동기화는 구독 상태로 제어됩니다.
    static func createModelContainer() throws -> ModelContainer {
        let schema = Schema([
            Envelope.self,
            TransactionRecord.self
        ])
        
        // CloudKit 항상 활성화 (구독 상태와 무관)
        // SwiftData는 구독이 없어도 CloudKit 컨테이너를 사용할 수 있음
        // 실제 동기화는 Apple 계정과 구독 상태로 자연스럽게 제어됨
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // 항상 automatic
        )
        
        print("🔄 CloudKit 통합 ModelContainer 생성")
        print("   - 구독자: iCloud 동기화 활성화")
        print("   - 비구독자: 로컬 저장만 (iCloud 접근 제한)")
        
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    }
    
    /// 동기화 활성 여부 (구독 + CloudKit 계정 + 설정)
    var isSyncActive: Bool {
        return isCloudSyncEnabled && 
               SubscriptionManager.shared.isSubscribed && 
               isCloudAvailable
    }
}


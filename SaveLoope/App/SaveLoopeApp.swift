import SwiftUI
import SwiftData

@main
struct SaveLoopeApp: App {
    @StateObject private var dateSelection = DateSelectionState()
    @StateObject private var cloudSyncManager = CloudSyncManager.shared
    
    // ModelContainer를 앱 시작 시점에 한 번만 생성
    private static let sharedModelContainer: ModelContainer = {
        do {
            // 앱 시작 시점의 설정 값으로 컨테이너 생성
            let isCloudSyncEnabled = UserDefaults.standard.bool(forKey: "isCloudSyncEnabled")
            let container = try CloudSyncManager.createModelContainer(
                enableCloudSync: isCloudSyncEnabled
            )
            
            if isCloudSyncEnabled {
                print("✅ 아이클라우드 동기화 활성화됨")
            } else {
                print("ℹ️ 로컬 저장소만 사용 중")
            }
            
            return container
        } catch {
            print("❌ ModelContainer 생성 실패: \(error.localizedDescription)")
            // Fallback: 로컬 전용 컨테이너 생성
            do {
                return try CloudSyncManager.createModelContainer(enableCloudSync: false)
            } catch {
                fatalError("ModelContainer 생성에 실패했습니다: \(error.localizedDescription)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(dateSelection)
                .environmentObject(cloudSyncManager)
        }
        .modelContainer(Self.sharedModelContainer)
    }
}

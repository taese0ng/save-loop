import SwiftUI
import SwiftData

@main
struct SaveLoopeApp: App {
    @StateObject private var dateSelection = DateSelectionState()
    @StateObject private var cloudSyncManager = CloudSyncManager.shared
    @State private var showLaunchView = true

    // ModelContainer를 앱 시작 시점에 한 번만 생성
    // CloudKit은 항상 활성화 상태로, 실제 동기화는 구독 상태로 제어
    private static let sharedModelContainer: ModelContainer = {
        do {
            let container = try CloudSyncManager.createModelContainer()
            print("✅ ModelContainer 생성 완료 (CloudKit 통합)")
            return container
        } catch {
            print("❌ ModelContainer 생성 실패: \(error.localizedDescription)")
            fatalError("ModelContainer 생성에 실패했습니다: \(error.localizedDescription)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            if showLaunchView {
                LaunchView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showLaunchView = false
                            }
                        }
                    }
            } else {
                MainTabView()
                    .environmentObject(dateSelection)
                    .environmentObject(cloudSyncManager)
            }
        }
        .modelContainer(Self.sharedModelContainer)
    }
}

import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.modelContext) private var modelContext: ModelContext
    @EnvironmentObject private var cloudSyncManager: CloudSyncManager
    @State private var showingResetAlert: Bool = false
    @State private var showingSyncChangeAlert: Bool = false
    @State private var showingCloudUnavailableAlert: Bool = false


    // 개발자 모드 관련 (앱 세션 동안만 유지, 재시작 시 자동 비활성화)
    @State private var isDeveloperModeEnabled: Bool = false
    @State private var showingDeveloperModeAlert: Bool = false
    @State private var showingPasswordPrompt: Bool = false
    @State private var passwordInput: String = ""
    @State private var tapCount: Int = 0
    @State private var tapTimer: Timer?
    
    // 개발자 모드 비밀번호 (원하는 비밀번호로 변경하세요)
    private let developerPassword: String = "1234" // TODO: 원하는 비밀번호로 변경
    
    var body: some View {
        VStack(spacing: 0) {
            SettingsHeader(
                isDeveloperModeEnabled: $isDeveloperModeEnabled,
                onDeveloperModeTap: handleDeveloperModeTap
            )

            settingsList
        }
        .background(Color("Background"))
        .task {
            // 뷰가 나타날 때 iCloud 상태 다시 확인
            await cloudSyncManager.checkCloudAccountStatus()
        }
        .onDisappear {
            // 뷰가 사라질 때 타이머 정리
            tapTimer?.invalidate()
            tapTimer = nil
        }
    }
    
    private var settingsList: some View {
        List {
            Section {
                CurrencySettingsSection()
                
                RenewalDaySettingsSection()
                
                CloudSyncSection(
                    subscriptionManager: subscriptionManager,
                    cloudSyncManager: cloudSyncManager,
                    showingCloudUnavailableAlert: $showingCloudUnavailableAlert,
                    showingSyncChangeAlert: $showingSyncChangeAlert
                )
            } header: {
                Text("settings.currency.section_header".localized) // 일반
            }
            
            Section {
                MembershipSection(
                    subscriptionManager: subscriptionManager
                )

                PlanComparisonSection()
            } header: {
                Text("settings.membership.section_header".localized) // 멤버십
            }

            // 개발자 전용 섹션
            if isDeveloperModeEnabled {
                DeveloperSection(
                    showingResetAlert: $showingResetAlert,
                    isDeveloperModeEnabled: $isDeveloperModeEnabled,
                    showingDeveloperModeAlert: $showingDeveloperModeAlert
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("Background"))
        .alert("settings.reset_data", isPresented: $showingResetAlert) { // 데이터 초기화
            Button("common.cancel", role: .cancel) { } // 취소
            Button("common.delete", role: .destructive) { // 삭제
                viewModel.resetAllData(context: modelContext)
            }
        } message: {
            Text("settings.reset_data_confirm") // 모든 봉투와 거래 기록이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.
        }
        .alert("alert.app_restart_required", isPresented: $showingSyncChangeAlert) { // 앱 재시작 필요
            Button("common.ok", role: .cancel) { } // 확인
        } message: {
            Text(cloudSyncManager.isCloudSyncEnabled
                ? "alert.cloud_sync_enabled" // iCloud 동기화가 활성화됩니다. 앱을 완전히 종료한 후 다시 시작해주세요.
                : "alert.cloud_sync_disabled") // iCloud 동기화가 비활성화됩니다. 앱을 완전히 종료한 후 다시 시작해주세요.
        }
        .alert("alert.cloud_unavailable", isPresented: $showingCloudUnavailableAlert) { // iCloud 사용 불가
            Button("common.ok", role: .cancel) { } // 확인
            Button("alert.open_settings") { // 설정으로 이동
                if let url = URL(string: "App-Prefs:root=CASTLE") {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text(cloudSyncManager.cloudAccountError ?? "alert.cloud_not_logged_in".localized) // iCloud에 로그인되어 있지 않습니다. 설정 앱에서 iCloud에 로그인해주세요.
        }
        .alert("settings.developer_mode", isPresented: $showingDeveloperModeAlert) { // 개발자 모드
            Button("common.ok", role: .cancel) { } // 확인
        } message: {
            Text(isDeveloperModeEnabled
                ? "settings.developer_mode.enabled" // 개발자 모드가 활성화되었습니다. 🛠️
                : "settings.developer_mode.disabled") // 개발자 모드가 비활성화되었습니다.
        }
        .alert("settings.developer_mode.unlock", isPresented: $showingPasswordPrompt) { // 개발자 모드 잠금 해제
            SecureField("settings.developer_mode.password", text: $passwordInput) // 비밀번호
            Button("common.cancel", role: .cancel) { // 취소
                passwordInput = ""
            }
            Button("common.ok") { // 확인
                handlePasswordInput()
            }
        } message: {
            Text("settings.developer_mode.password_prompt") // 개발자 전용 기능에 접근하려면 비밀번호를 입력하세요.
        }
    }
    
    // MARK: - 개발자 모드 탭 처리
    private func handleDeveloperModeTap() {
        tapCount += 1
        
        // 기존 타이머 취소
        tapTimer?.invalidate()
        
        // 7번 탭하면 비밀번호 프롬프트 표시
        if tapCount >= 7 {
            showingPasswordPrompt = true
            tapCount = 0
            
            // 햅틱 피드백
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        } else {
            // 2초 내에 다시 탭하지 않으면 카운트 리셋
            tapTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                tapCount = 0
            }
        }
    }
    
    // MARK: - 개발자 모드 비밀번호 검증
    private func handlePasswordInput() {
        if passwordInput == developerPassword {
            // 비밀번호 일치 - 개발자 모드 활성화 (앱 세션 동안만 유지)
            isDeveloperModeEnabled = true
            showingDeveloperModeAlert = true
            
            // 성공 햅틱
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            print("🛠️ 개발자 모드 활성화됨 (앱 세션 동안만 유효)")
        } else {
            // 비밀번호 불일치 - 에러 햅틱
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            
            print("❌ 잘못된 비밀번호")
        }
        
        // 비밀번호 입력 필드 초기화
        passwordInput = ""
    }
}

#Preview {
    SettingsView()
        .environmentObject(CloudSyncManager.shared)
}

import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
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
            // 커스텀 헤더 (개발자 모드 활성화용 탭 제스처)
            HStack {
                Text("설정")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if isDeveloperModeEnabled {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                // 개발자 모드가 비활성화 상태일 때만 탭 카운트
                if !isDeveloperModeEnabled {
                    handleDeveloperModeTap()
                }
            }
            
            List {
                // iCloud 동기화 섹션
                Section {
                    HStack {
                        Image(systemName: "icloud")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("iCloud 동기화")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { cloudSyncManager.isCloudSyncEnabled },
                            set: { newValue in
                                // iCloud를 켜려고 할 때만 상태 확인
                                if newValue && !cloudSyncManager.isCloudAvailable {
                                    showingCloudUnavailableAlert = true
                                    return
                                }
                                cloudSyncManager.isCloudSyncEnabled = newValue
                                showingSyncChangeAlert = true
                            }
                        ))
                        .labelsHidden()
                        .tint(.blue)
                    }
                    
                    // iCloud 상태 표시
                    if !cloudSyncManager.isCloudAvailable {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text(cloudSyncManager.cloudAccountError ?? "iCloud를 사용할 수 없습니다")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("동기화")
                } footer: {
                    Text("iCloud를 사용하여 여러 기기 간에 데이터를 동기화합니다. 설정 변경은 앱을 재시작한 후 적용됩니다.")
                        .foregroundColor(.secondary)
                }
                
                // 개발자 전용 섹션
                if isDeveloperModeEnabled {
                    Section {
                        Button(action: {
                            showingResetAlert = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                Text("데이터 초기화")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // 개발자 모드 비활성화 버튼
                        Button(action: {
                            isDeveloperModeEnabled = false
                            showingDeveloperModeAlert = true
                        }) {
                            HStack {
                                Image(systemName: "hammer.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 24)
                                Text("개발자 모드 비활성화")
                                    .foregroundColor(.orange)
                            }
                        }
                    } header: {
                        Text("개발자 도구")
                    } footer: {
                        Text("⚠️ 개발자 전용 기능입니다. 데이터 초기화 시 모든 봉투(Envelope)와 거래 기록(Transaction Record)이 삭제됩니다.")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .alert("데이터 초기화", isPresented: $showingResetAlert) {
                Button("취소", role: .cancel) { }
                Button("초기화", role: .destructive) {
                    viewModel.resetAllData(context: modelContext)
                }
            } message: {
                Text("모든 봉투와 거래 기록이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
            .alert("앱 재시작 필요", isPresented: $showingSyncChangeAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(cloudSyncManager.isCloudSyncEnabled 
                    ? "iCloud 동기화가 활성화됩니다. 앱을 완전히 종료한 후 다시 시작해주세요." 
                    : "iCloud 동기화가 비활성화됩니다. 앱을 완전히 종료한 후 다시 시작해주세요.")
            }
            .alert("iCloud 사용 불가", isPresented: $showingCloudUnavailableAlert) {
                Button("확인", role: .cancel) { }
                Button("설정으로 이동") {
                    if let url = URL(string: "App-Prefs:root=CASTLE") {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text(cloudSyncManager.cloudAccountError ?? "iCloud에 로그인되어 있지 않습니다. 설정 앱에서 iCloud에 로그인해주세요.")
            }
            .alert("개발자 모드", isPresented: $showingDeveloperModeAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(isDeveloperModeEnabled 
                    ? "개발자 모드가 활성화되었습니다. 🛠️" 
                    : "개발자 모드가 비활성화되었습니다.")
            }
            .alert("개발자 모드 잠금 해제", isPresented: $showingPasswordPrompt) {
                SecureField("비밀번호", text: $passwordInput)
                Button("취소", role: .cancel) {
                    passwordInput = ""
                }
                Button("확인") {
                    handlePasswordInput()
                }
            } message: {
                Text("개발자 전용 기능에 접근하려면 비밀번호를 입력하세요.")
            }
        }
        .background(Color.white)
        .task {
            // 뷰가 나타날 때 iCloud 상태 다시 확인
            await cloudSyncManager.checkCloudAccountStatus()
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

import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext: ModelContext
    @EnvironmentObject private var cloudSyncManager: CloudSyncManager
    @State private var showingResetAlert: Bool = false
    @State private var showingSyncChangeAlert: Bool = false
    @State private var showingCloudUnavailableAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 커스텀 헤더
            Text("설정")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)
                .background(Color.white)
            
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
                
                // 데이터 관리 섹션
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
                } header: {
                    Text("데이터 관리")
                } footer: {
                    Text("모든 봉투(Envelope)와 거래 기록(Transaction Record)이 삭제됩니다.")
                        .foregroundColor(.secondary)
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
        }
        .background(Color.white)
        .task {
            // 뷰가 나타날 때 iCloud 상태 다시 확인
            await cloudSyncManager.checkCloudAccountStatus()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(CloudSyncManager.shared)
}

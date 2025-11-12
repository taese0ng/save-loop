import SwiftUI

struct CloudSyncSection: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var cloudSyncManager: CloudSyncManager
    @Binding var showingCloudUnavailableAlert: Bool
    @Binding var showingSyncChangeAlert: Bool
    @State private var showingSubscriptionView = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "icloud")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text("settings.cloud_sync.title".localized) // iCloud 동기화
                Spacer()
                Toggle("", isOn: Binding(
                    get: { cloudSyncManager.isCloudSyncEnabled },
                    set: { newValue in
                        // iCloud를 켜려고 할 때만 상태 확인
                        if newValue {
                            // 1. 구독 상태 확인
                            if !subscriptionManager.isSubscribed {
                                showingSubscriptionView = true
                                return
                            }

                            // 2. iCloud 계정 상태 확인
                            if !cloudSyncManager.isCloudAvailable {
                                showingCloudUnavailableAlert = true
                                return
                            }
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
                    Text(cloudSyncManager.cloudAccountError ?? "settings.cloud_sync.unavailable".localized) // iCloud를 사용할 수 없습니다
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView(showsCloseButton: false)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
}

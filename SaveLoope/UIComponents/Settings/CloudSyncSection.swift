import SwiftUI

struct CloudSyncSection: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @ObservedObject var cloudSyncManager: CloudSyncManager
    @Binding var showingSubscriptionView: Bool
    @Binding var showingCloudUnavailableAlert: Bool
    @Binding var showingSyncChangeAlert: Bool

    var body: some View {
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
                    Text(cloudSyncManager.cloudAccountError ?? "iCloud를 사용할 수 없습니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("동기화")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if !subscriptionManager.isSubscribed {
                    Text("⭐️ iCloud 동기화는 프리미엄 전용 기능입니다")
                        .foregroundColor(.blue)
                }
                Text("iCloud를 사용하여 여러 기기 간에 데이터를 동기화합니다. 설정 변경은 앱을 재시작한 후 적용됩니다.")
                    .foregroundColor(.secondary)
            }
        }
    }
}

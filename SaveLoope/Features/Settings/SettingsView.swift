import SwiftUI
import SwiftData

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.modelContext) private var modelContext: ModelContext
    @State private var showingResetAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("데이터 초기화")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("데이터 관리")
                } footer: {
                    Text("모든 봉투(Envelope)와 거래 기록(Transaction Record)이 삭제됩니다.")
                }
            }
            .navigationTitle("설정")
            .alert("데이터 초기화", isPresented: $showingResetAlert) {
                Button("취소", role: .cancel) { }
                Button("초기화", role: .destructive) {
                    viewModel.resetAllData(context: modelContext)
                }
            } message: {
                Text("모든 봉투와 거래 기록이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
        }
    }
}

#Preview {
    SettingsView()
}

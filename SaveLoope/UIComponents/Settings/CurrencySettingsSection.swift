import SwiftUI

struct CurrencySettingsSection: View {
    @State private var showingCurrencySettings = false
    @State private var currentCurrencyName: String = ""
    @State private var sheetId: UUID = UUID() // sheet의 고유 ID
    // CurrencyManager를 직접 관찰하지 않고, 필요할 때만 접근
    private var currencyManager: CurrencyManager {
        CurrencyManager.shared
    }
    
    var body: some View {
        Section {
            Button(action: {
                // 버튼 클릭 시 sheet 열기
                // sheet ID를 새로 생성하여 완전히 새로운 인스턴스로 열기
                sheetId = UUID()
                showingCurrencySettings = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("통화 설정")
                            .foregroundColor(.primary)
                        
                        Text(currentCurrencyName.isEmpty ? "로딩 중..." : currentCurrencyName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("일반")
        }
        .sheet(isPresented: $showingCurrencySettings) {
            CurrencySettingsView(
                showingCurrencySettings: $showingCurrencySettings,
                onCurrencyChanged: {
                    // 통화 변경 시 이름 업데이트 (sheet가 닫힌 후에 업데이트)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        updateCurrencyName()
                    }
                }
            )
            .id(sheetId) // 고유 ID로 sheet 인스턴스 고정
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
        }
        .onAppear {
            // 초기 통화 이름 설정 (sheet가 열려있지 않을 때만)
            if currentCurrencyName.isEmpty && !showingCurrencySettings {
                updateCurrencyName()
            }
        }
        .onChange(of: showingCurrencySettings) { oldValue, newValue in
            // sheet가 닫힐 때만 통화 이름 업데이트
            if oldValue && !newValue {
                // sheet가 닫힌 후 약간의 지연을 두고 업데이트
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    updateCurrencyName()
                }
            }
        }
    }
    
    @MainActor
    private func updateCurrencyName() {
        // sheet가 열려있을 때는 업데이트하지 않음
        guard !showingCurrencySettings else { return }
        currentCurrencyName = currencyManager.selectedCurrency.displayName
    }
}


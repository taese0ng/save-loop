import SwiftUI

struct CurrencySettingsSection: View {
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var showingCurrencySettings = false
    @State private var currencies: [Currency] = []
    @State private var selectedCurrencyCode: String = ""
    
    private var currentCurrencyName: String {
        currencyManager.selectedCurrency.displayName
    }

    var body: some View {
        Button(action: {
            // 데이터 준비 (항상 최신 데이터로 업데이트)
            currencies = currencyManager.getCurrenciesWithDeviceFirst()
            selectedCurrencyCode = currencyManager.selectedCurrency.code
            showingCurrencySettings = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.currency_settings".localized) // 통화 설정
                        .foregroundColor(.primary)

                    Text(currentCurrencyName.isEmpty ? "common.loading".localized : currentCurrencyName) // 로딩 중...
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingCurrencySettings) {
            CurrencySettingsView(
                currencies: currencies,
                selectedCurrencyCode: selectedCurrencyCode,
                onCurrencyChanged: { newCode in
                    selectedCurrencyCode = newCode
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
}


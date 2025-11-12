import SwiftUI

struct CurrencySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    let currencies: [Currency]
    @State private var selectedCurrencyCode: String
    var onCurrencyChanged: ((String) -> Void)?
    // CurrencyManager를 직접 관찰하지 않고, 필요할 때만 접근
    private var currencyManager: CurrencyManager {
        CurrencyManager.shared
    }
    
    // currencies가 비어있으면 CurrencyManager에서 직접 가져오기
    private var displayCurrencies: [Currency] {
        currencies.isEmpty ? currencyManager.getCurrenciesWithDeviceFirst() : currencies
    }

    init(currencies: [Currency], selectedCurrencyCode: String, onCurrencyChanged: ((String) -> Void)? = nil) {
        self.currencies = currencies
        self._selectedCurrencyCode = State(initialValue: selectedCurrencyCode)
        self.onCurrencyChanged = onCurrencyChanged
    }

    var body: some View {
        StandardSheetContainer(title: "currency.settings_title".localized) { // 통화 설정
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(displayCurrencies) { currency in
                        let isSelected = selectedCurrencyCode == currency.code
                        // 앱 언어 설정에 따른 통화인지 확인
                        let languageCode = LocalizationManager.shared.currentLanguage
                        let isDeviceCurrency = Currency.currencyFromAppLanguage(languageCode)?.code == currency.code

                        Button(action: {
                            // 햅틱 피드백
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()

                            currencyManager.setCurrency(currency)
                            selectedCurrencyCode = currency.code
                            onCurrencyChanged?(currency.code)

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 12) {
                                // 통화 심볼 (원형 배경)
                                Text(currency.symbol)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5) // 텍스트가 프레임 안에 맞도록 최대 50%까지 축소
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                                    )

                                // 통화 정보
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(currency.localizedName) // 다국어 지원된 이름 사용
                                            .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)

                                        if isDeviceCurrency {
                                            Text("currency.device_badge".localized) // 기기
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.blue)
                                                )
                                        }
                                    }

                                    Text(currency.code)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }

                                Spacer(minLength: 8)

                                // 선택 표시 (애니메이션)
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 24))
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isSelected ? Color.blue.opacity(0.05) : Color.clear)
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if currency.id != displayCurrencies.last?.id {
                            Divider()
                                .padding(.leading, 88)
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .scrollContentBackground(.hidden)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCurrencyCode)
        .onAppear {
            // 뷰가 나타날 때 현재 선택된 통화로 업데이트
            selectedCurrencyCode = currencyManager.selectedCurrency.code
        }
    }
}


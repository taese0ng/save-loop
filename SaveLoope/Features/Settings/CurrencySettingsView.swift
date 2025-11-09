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

    init(currencies: [Currency], selectedCurrencyCode: String, onCurrencyChanged: ((String) -> Void)? = nil) {
        self.currencies = currencies
        self._selectedCurrencyCode = State(initialValue: selectedCurrencyCode)
        self.onCurrencyChanged = onCurrencyChanged
    }

    var body: some View {
        VStack(spacing: 0) {
            // 개선된 헤더
            VStack(spacing: 8) {
                // 드래그 인디케이터
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)

                Text("통화 설정")
                    .font(.title3)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .background(Color(UIColor.systemGroupedBackground))

            // 통화 목록
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(currencies) { currency in
                        let isSelected = selectedCurrencyCode == currency.code
                        let isDeviceCurrency = Currency.currencyFromDeviceLocale()?.code == currency.code

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
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                                    )

                                // 통화 정보
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text(currency.name)
                                            .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)

                                        if isDeviceCurrency {
                                            Text("기기")
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

                        if currency.id != currencies.last?.id {
                            Divider()
                                .padding(.leading, 88)
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedCurrencyCode)
    }
}


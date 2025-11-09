import SwiftUI

struct CurrencySettingsView: View {
    @Binding var showingCurrencySettings: Bool
    var onCurrencyChanged: (() -> Void)? = nil
    // CurrencyManager를 직접 관찰하지 않고, 필요할 때만 접근
    private var currencyManager: CurrencyManager {
        CurrencyManager.shared
    }
    @State private var currencies: [Currency] = []
    @State private var isLoaded: Bool = false
    @State private var selectedCurrencyCode: String = "" // 선택된 통화 코드를 별도로 관리
    
    var body: some View {
        NavigationView {
            List {
                if isLoaded {
                    ForEach(currencies) { currency in
                    Button(action: {
                        // 통화 변경
                        currencyManager.setCurrency(currency)
                        selectedCurrencyCode = currency.code
                        onCurrencyChanged?()
                        // 통화 변경 후 sheet 닫기
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showingCurrencySettings = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            // 통화 심볼
                            Text(currency.symbol)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(minWidth: 55, maxWidth: 60, alignment: .leading)
                                .fixedSize(horizontal: true, vertical: false)
                            
                            // 통화 정보 (한 줄로 표시)
                            HStack(spacing: 4) {
                                // 통화 이름
                                Text(currency.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                                
                                // 통화 코드
                                Text("(\(currency.code))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                
                                // 기기 설정 통화 표시
                                if let deviceCurrency = Currency.currencyFromDeviceLocale(),
                                   deviceCurrency.code == currency.code {
                                    Text("• 기기 설정")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer(minLength: 8)
                            
                            // 선택 표시
                            if selectedCurrencyCode == currency.code {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                            }
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    // 로딩 중 표시
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("통화 설정")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
            .contentMargins(.top, -10, for: .scrollContent) // 타이틀과 리스트 간격 조정
        }
        .onAppear {
            // sheet가 완전히 나타난 후에만 데이터 로드
            // 약간의 지연을 두어 sheet가 안정적으로 열린 후에 로드
            // 이미 로드된 경우 다시 로드하지 않음
            guard !isLoaded else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // sheet가 여전히 열려있는지 확인
                guard showingCurrencySettings else { return }
                
                currencies = currencyManager.getCurrenciesWithDeviceFirst()
                selectedCurrencyCode = currencyManager.selectedCurrency.code
                isLoaded = true
            }
        }
        .onDisappear {
            // sheet가 닫힐 때 상태 초기화
            isLoaded = false
            currencies = []
            selectedCurrencyCode = ""
        }
    }
}


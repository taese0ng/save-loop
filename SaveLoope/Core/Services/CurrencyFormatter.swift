import Foundation

/// 통화 포맷팅을 담당하는 유틸리티
struct CurrencyFormatter {
    let currency: Currency
    
    @MainActor
    init(currency: Currency? = nil) {
        if let currency = currency {
            self.currency = currency
        } else {
            self.currency = CurrencyManager.shared.selectedCurrency
        }
    }
    
    /// 금액을 통화 형식으로 포맷팅
    /// - Parameters:
    ///   - amount: 금액 (Double - 실제 금액, 예: 100.5)
    ///   - showDecimal: 소수점 표시 여부 (nil이면 자동 판단)
    /// - Returns: 포맷팅된 문자열
    func format(_ amount: Double, showDecimal: Bool? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true

        // 소수점 이하가 0이면 정수로 표시
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        } else {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
        }

        let number = NSNumber(value: amount)
        let formattedNumber = formatter.string(from: number) ?? "\(amount)"

        // 통화 심볼과 함께 반환
        return "\(formattedNumber)\(currency.symbol)"
    }
    
}

/// Double 확장 - 통화 포맷팅
extension Double {
    /// 현재 선택된 통화로 포맷팅
    @MainActor
    var formattedCurrency: String {
        CurrencyFormatter().format(self)
    }
}


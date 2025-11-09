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
    ///   - amount: 금액 (Int)
    ///   - showDecimal: 소수점 표시 여부 (nil이면 자동 판단)
    /// - Returns: 포맷팅된 문자열
    func format(_ amount: Int, showDecimal: Bool? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        
        // 소수점 처리
        let shouldShowDecimal = showDecimal ?? currency.requiresDecimal
        
        if shouldShowDecimal {
            // 소수점이 필요한 통화는 소수점 2자리까지 표시
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 2
        } else {
            // 소수점이 필요 없는 통화는 정수만 표시
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        }
        
        let number = NSNumber(value: amount)
        let formattedNumber = formatter.string(from: number) ?? "\(amount)"
        
        // 통화 심볼과 함께 반환
        return "\(formattedNumber)\(currency.symbol)"
    }
    
    /// 금액을 통화 형식으로 포맷팅 (Double 버전)
    /// - Parameters:
    ///   - amount: 금액 (Double)
    ///   - showDecimal: 소수점 표시 여부 (nil이면 자동 판단)
    /// - Returns: 포맷팅된 문자열
    func format(_ amount: Double, showDecimal: Bool? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        
        // 소수점 처리
        let shouldShowDecimal = showDecimal ?? currency.requiresDecimal
        
        if shouldShowDecimal {
            // 소수점이 필요한 통화는 소수점 2자리까지 표시
            // 단, 소수점이 0이면 표시하지 않음
            let roundedAmount = round(amount * 100) / 100
            if roundedAmount == floor(roundedAmount) {
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = 0
            } else {
                formatter.minimumFractionDigits = 2
                formatter.maximumFractionDigits = 2
            }
        } else {
            // 소수점이 필요 없는 통화는 정수만 표시
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        }
        
        let number = NSNumber(value: amount)
        let formattedNumber = formatter.string(from: number) ?? "\(Int(amount))"
        
        // 통화 심볼과 함께 반환
        return "\(formattedNumber)\(currency.symbol)"
    }
}

/// Int 확장 - 통화 포맷팅
extension Int {
    /// 현재 선택된 통화로 포맷팅
    @MainActor
    var formattedCurrency: String {
        CurrencyFormatter().format(self)
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


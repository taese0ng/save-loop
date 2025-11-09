import Foundation
import SwiftUI

/// 통화 설정을 관리하는 매니저
@MainActor
class CurrencyManager: ObservableObject {
    @MainActor static let shared = CurrencyManager()
    
    @Published var selectedCurrency: Currency {
        didSet {
            UserDefaults.standard.set(selectedCurrency.code, forKey: "selectedCurrencyCode")
        }
    }
    
    private let currencyCodeKey = "selectedCurrencyCode"
    
    private init() {
        // 저장된 통화 코드 불러오기
        if let savedCode = UserDefaults.standard.string(forKey: currencyCodeKey),
           let savedCurrency = Currency.supportedCurrencies.first(where: { $0.code == savedCode }) {
            self.selectedCurrency = savedCurrency
        } else {
            // 저장된 설정이 없으면 기기 로케일에서 가져오기
            if let deviceCurrency = Currency.currencyFromDeviceLocale() {
                self.selectedCurrency = deviceCurrency
            } else {
                // 기기 로케일에서도 찾을 수 없으면 기본값 (원화)
                self.selectedCurrency = Currency.default
            }
        }
    }
    
    /// 통화 변경
    func setCurrency(_ currency: Currency) {
        selectedCurrency = currency
    }
    
    /// 지원되는 통화 목록 가져오기 (기기 통화를 최상단에 배치)
    func getCurrenciesWithDeviceFirst() -> [Currency] {
        guard let deviceCurrency = Currency.currencyFromDeviceLocale() else {
            return Currency.supportedCurrencies
        }
        
        var currencies = Currency.supportedCurrencies
        // 기기 통화를 제거하고 최상단에 추가
        currencies.removeAll { $0.code == deviceCurrency.code }
        return [deviceCurrency] + currencies
    }
    
    /// 현재 선택된 통화 심볼 (nonisolated 접근 가능)
    nonisolated var currentSymbol: String {
        // UserDefaults에서 직접 읽어서 심볼 반환
        if let savedCode = UserDefaults.standard.string(forKey: currencyCodeKey),
           let savedCurrency = Currency.supportedCurrencies.first(where: { $0.code == savedCode }) {
            return savedCurrency.symbol
        } else if let deviceCurrency = Currency.currencyFromDeviceLocale() {
            return deviceCurrency.symbol
        } else {
            return Currency.default.symbol
        }
    }
}


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
            // 저장된 설정이 없으면 앱 언어 설정에 따른 통화 가져오기
            let languageCode = LocalizationManager.shared.currentLanguage
            if let deviceCurrency = Currency.currencyFromAppLanguage(languageCode) {
                self.selectedCurrency = deviceCurrency
            } else {
                // 언어에 맞는 통화를 찾을 수 없으면 기본값 (원화)
                self.selectedCurrency = Currency.default
            }
        }
    }
    
    /// 통화 변경
    func setCurrency(_ currency: Currency) {
        selectedCurrency = currency
    }
    
    /// 지원되는 통화 목록 가져오기 (앱 언어에 맞는 통화를 최상단에 배치)
    func getCurrenciesWithDeviceFirst() -> [Currency] {
        // 앱 언어 설정에 따른 통화 가져오기
        let languageCode = LocalizationManager.shared.currentLanguage
        guard let deviceCurrency = Currency.currencyFromAppLanguage(languageCode) else {
            return Currency.supportedCurrencies
        }
        
        var currencies = Currency.supportedCurrencies
        // 언어에 맞는 통화를 제거하고 최상단에 추가
        currencies.removeAll { $0.code == deviceCurrency.code }
        return [deviceCurrency] + currencies
    }
    
    /// 현재 선택된 통화 심볼 (nonisolated 접근 가능)
    nonisolated var currentSymbol: String {
        // UserDefaults에서 직접 읽어서 심볼 반환
        if let savedCode = UserDefaults.standard.string(forKey: currencyCodeKey),
           let savedCurrency = Currency.supportedCurrencies.first(where: { $0.code == savedCode }) {
            return savedCurrency.symbol
        } else {
            // 앱 언어 설정에 따른 통화 가져오기
            let languageCode = LocalizationManager.shared.currentLanguage
            if let deviceCurrency = Currency.currencyFromAppLanguage(languageCode) {
                return deviceCurrency.symbol
            } else {
                return Currency.default.symbol
            }
        }
    }
}


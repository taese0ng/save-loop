import Foundation

/// 통화 정보를 나타내는 모델
struct Currency: Identifiable, Codable, Hashable {
    let id: String // 통화 코드 (예: "KRW", "USD")
    let code: String // ISO 4217 통화 코드
    let symbol: String // 통화 심볼 (예: "₩", "$")
    let name: String // 통화 이름 (예: "원", "달러")
    let localeIdentifier: String // 로케일 식별자 (예: "ko_KR", "en_US")
    
    /// 소수점이 필요한 통화인지 확인
    var requiresDecimal: Bool {
        // 원화, 엔화 등은 소수점이 필요 없음
        let noDecimalCurrencies = ["KRW", "JPY", "VND", "IDR", "CLP", "UGX", "PYG", "KMF", "MGA", "MZN", "RWF", "XOF", "XAF", "XPF"]
        return !noDecimalCurrencies.contains(code)
    }
    
    /// 다국어 지원된 통화 이름
    var localizedName: String {
        return "currency.name.\(code)".localized
    }
    
    /// 표시 이름 (예: "원 (KRW)")
    var displayName: String {
        "\(localizedName) (\(code))"
    }
}

/// 주요 통화 목록
extension Currency {
    static let supportedCurrencies: [Currency] = [
        // 아시아
        Currency(id: "KRW", code: "KRW", symbol: "₩", name: "원", localeIdentifier: "ko_KR"),
        Currency(id: "JPY", code: "JPY", symbol: "¥", name: "엔", localeIdentifier: "ja_JP"),
        Currency(id: "CNY", code: "CNY", symbol: "¥", name: "위안", localeIdentifier: "zh_CN"),
        Currency(id: "HKD", code: "HKD", symbol: "HK$", name: "홍콩 달러", localeIdentifier: "zh_HK"),
        Currency(id: "SGD", code: "SGD", symbol: "S$", name: "싱가포르 달러", localeIdentifier: "en_SG"),
        Currency(id: "TWD", code: "TWD", symbol: "NT$", name: "신대만 달러", localeIdentifier: "zh_TW"),
        Currency(id: "THB", code: "THB", symbol: "฿", name: "바트", localeIdentifier: "th_TH"),
        Currency(id: "VND", code: "VND", symbol: "₫", name: "동", localeIdentifier: "vi_VN"),
        Currency(id: "IDR", code: "IDR", symbol: "Rp", name: "루피아", localeIdentifier: "id_ID"),
        Currency(id: "MYR", code: "MYR", symbol: "RM", name: "링깃", localeIdentifier: "ms_MY"),
        Currency(id: "PHP", code: "PHP", symbol: "₱", name: "페소", localeIdentifier: "en_PH"),
        Currency(id: "INR", code: "INR", symbol: "₹", name: "루피", localeIdentifier: "en_IN"),
        
        // 유럽
        Currency(id: "EUR", code: "EUR", symbol: "€", name: "유로", localeIdentifier: "de_DE"),
        Currency(id: "GBP", code: "GBP", symbol: "£", name: "파운드", localeIdentifier: "en_GB"),
        Currency(id: "CHF", code: "CHF", symbol: "CHF", name: "프랑", localeIdentifier: "de_CH"),
        Currency(id: "RUB", code: "RUB", symbol: "₽", name: "루블", localeIdentifier: "ru_RU"),
        Currency(id: "PLN", code: "PLN", symbol: "zł", name: "즈워티", localeIdentifier: "pl_PL"),
        Currency(id: "SEK", code: "SEK", symbol: "kr", name: "크로나", localeIdentifier: "sv_SE"),
        Currency(id: "NOK", code: "NOK", symbol: "kr", name: "크로네", localeIdentifier: "nb_NO"),
        Currency(id: "DKK", code: "DKK", symbol: "kr", name: "크로네", localeIdentifier: "da_DK"),
        
        // 아메리카
        Currency(id: "USD", code: "USD", symbol: "$", name: "달러", localeIdentifier: "en_US"),
        Currency(id: "CAD", code: "CAD", symbol: "C$", name: "캐나다 달러", localeIdentifier: "en_CA"),
        Currency(id: "MXN", code: "MXN", symbol: "Mex$", name: "페소", localeIdentifier: "es_MX"),
        Currency(id: "BRL", code: "BRL", symbol: "R$", name: "레알", localeIdentifier: "pt_BR"),
        Currency(id: "ARS", code: "ARS", symbol: "$", name: "페소", localeIdentifier: "es_AR"),
        Currency(id: "CLP", code: "CLP", symbol: "$", name: "페소", localeIdentifier: "es_CL"),
        
        // 오세아니아
        Currency(id: "AUD", code: "AUD", symbol: "A$", name: "호주 달러", localeIdentifier: "en_AU"),
        Currency(id: "NZD", code: "NZD", symbol: "NZ$", name: "뉴질랜드 달러", localeIdentifier: "en_NZ"),
        
        // 중동
        Currency(id: "AED", code: "AED", symbol: "د.إ", name: "디르함", localeIdentifier: "ar_AE"),
        Currency(id: "SAR", code: "SAR", symbol: "﷼", name: "리얄", localeIdentifier: "ar_SA"),
        Currency(id: "ILS", code: "ILS", symbol: "₪", name: "셰켈", localeIdentifier: "he_IL"),
        Currency(id: "TRY", code: "TRY", symbol: "₺", name: "리라", localeIdentifier: "tr_TR"),
    ]
    
    /// 기기 로케일에서 통화 코드 가져오기 (실제 기기 지역 설정 기반)
    static func currencyFromDeviceLocale() -> Currency? {
        let locale = Locale.current
        guard let currencyCode = locale.currency?.identifier else {
            return nil
        }
        
        // 지원되는 통화 목록에서 찾기
        return supportedCurrencies.first { $0.code == currencyCode }
    }
    
    /// 앱 언어 설정에 따른 기본 통화 가져오기
    static func currencyFromAppLanguage(_ languageCode: String) -> Currency? {
        // 언어 코드에 따른 기본 통화 매핑
        let currencyCode: String
        switch languageCode {
        case "ko":
            currencyCode = "KRW" // 한국어 -> 원화
        case "ja":
            currencyCode = "JPY" // 일본어 -> 엔
        case "zh-Hans":
            currencyCode = "CNY" // 중국어 간체 -> 위안
        case "zh-Hant":
            currencyCode = "TWD" // 중국어 번체 -> 신대만 달러
        case "en-US":
            currencyCode = "USD" // 영어 미국 -> 달러
        case "en-GB":
            currencyCode = "GBP" // 영어 영국 -> 파운드
        default:
            // 지원하지 않는 언어는 영어(미국) 기본값 사용
            currencyCode = "USD"
        }
        
        return supportedCurrencies.first { $0.code == currencyCode }
    }
    
    /// 기본 통화 (원화)
    static let `default` = Currency(id: "KRW", code: "KRW", symbol: "₩", name: "원", localeIdentifier: "ko_KR")
}


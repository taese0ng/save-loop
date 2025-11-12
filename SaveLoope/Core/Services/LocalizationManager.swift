//
//  LocalizationManager.swift
//  SaveLoope
//
//  Created on 2025-11-12
//

import Foundation
import SwiftUI

/// 다국어 지원을 위한 매니저 클래스
/// 앱 전반에 걸쳐 일관된 다국어 처리를 제공합니다.
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    /// 현재 선택된 언어 코드
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "AppLanguage")
        }
    }

    /// 지원하는 언어 목록
    static let supportedLanguages: [LanguageOption] = [
        LanguageOption(code: "ko", name: "한국어", englishName: "Korean"),
        LanguageOption(code: "en-US", name: "English (US)", englishName: "English (US)"),
        LanguageOption(code: "en-GB", name: "English (UK)", englishName: "English (UK)"),
        LanguageOption(code: "ja", name: "日本語", englishName: "Japanese"),
        LanguageOption(code: "zh-Hans", name: "简体中文", englishName: "Chinese (Simplified)"),
        LanguageOption(code: "zh-Hant", name: "繁體中文", englishName: "Chinese (Traditional)")
    ]

    private init() {
        // 시스템 언어 감지
        let systemLanguage = Locale.preferredLanguages.first ?? "en-US"
        let mappedSystemLanguage = LocalizationManager.mapSystemLanguage(systemLanguage)
        
        // 매핑된 언어가 지원되는 언어인지 확인
        let supportedLanguageCodes = LocalizationManager.supportedLanguages.map { $0.code }
        let validLanguage = supportedLanguageCodes.contains(mappedSystemLanguage) ? mappedSystemLanguage : "en-US"
        
        // 디버깅: 실제 감지된 언어 출력
        print("🌐 LocalizationManager 초기화:")
        print("   - Locale.preferredLanguages: \(Locale.preferredLanguages)")
        print("   - 시스템 언어: \(systemLanguage)")
        print("   - 매핑된 언어: \(mappedSystemLanguage)")
        print("   - 최종 선택된 언어: \(validLanguage)")
        print("   - 저장된 AppLanguage: \(UserDefaults.standard.string(forKey: "AppLanguage") ?? "없음")")
        
        // 항상 시스템 언어를 따름
        self.currentLanguage = validLanguage
    }

    /// 시스템 언어 코드를 앱에서 지원하는 언어 코드로 매핑
    private static func mapSystemLanguage(_ systemLanguage: String) -> String {
        // 시스템 언어 코드를 앱의 언어 코드로 변환
        if systemLanguage.hasPrefix("ko") {
            return "ko"
        } else if systemLanguage.hasPrefix("ja") {
            return "ja"
        } else if systemLanguage.hasPrefix("zh-Hans") || systemLanguage.hasPrefix("zh-CN") {
            return "zh-Hans"
        } else if systemLanguage.hasPrefix("zh-Hant") || systemLanguage.hasPrefix("zh-TW") || systemLanguage.hasPrefix("zh-HK") {
            return "zh-Hant"
        } else if systemLanguage.hasPrefix("en-GB") {
            return "en-GB"
        } else if systemLanguage.hasPrefix("en") {
            return "en-US"
        }

        // 지원하지 않는 언어는 영어(미국)로 기본 설정
        return "en-US"
    }

    /// 언어 변경 (향후 언어 선택 UI 추가 시 사용)
    func changeLanguage(to languageCode: String) {
        // 지원되는 언어인지 확인
        let supportedLanguageCodes = LocalizationManager.supportedLanguages.map { $0.code }
        let validLanguage = supportedLanguageCodes.contains(languageCode) ? languageCode : "en-US"
        
        currentLanguage = validLanguage
    }

    /// 현재 언어에 대한 Bundle 반환
    func getCurrentBundle() -> Bundle {
        // 현재 언어의 bundle 찾기
        if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            print("📦 Bundle 로드 성공: \(currentLanguage) -> \(path)")
            return bundle
        }
        
        print("⚠️ Bundle 로드 실패: \(currentLanguage).lproj를 찾을 수 없음")
        
        // 현재 언어의 bundle을 찾지 못하면 영어(미국) bundle 시도
        if let path = Bundle.main.path(forResource: "en-US", ofType: "lproj"),
           let bundle = Bundle(path: path) {
            print("📦 Fallback Bundle 로드: en-US -> \(path)")
            // 기본값을 영어로 변경
            currentLanguage = "en-US"
            return bundle
        }
        
        print("⚠️ Fallback Bundle도 없음. 메인 Bundle 사용")
        // 영어 bundle도 없으면 메인 bundle 반환
        return Bundle.main
    }

    /// 특정 키에 대한 번역 문자열 반환
    func localizedString(for key: String, comment: String = "") -> String {
        let bundle = getCurrentBundle()
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
    
    /// 현재 언어에 대한 Locale 반환
    func getCurrentLocale() -> Locale {
        let localeIdentifier: String
        switch currentLanguage {
        case "ko":
            localeIdentifier = "ko_KR"
        case "en-US":
            localeIdentifier = "en_US"
        case "en-GB":
            localeIdentifier = "en_GB"
        case "ja":
            localeIdentifier = "ja_JP"
        case "zh-Hans":
            localeIdentifier = "zh_Hans_CN"
        case "zh-Hant":
            localeIdentifier = "zh_Hant_TW"
        default:
            localeIdentifier = "en_US"
        }
        return Locale(identifier: localeIdentifier)
    }
}

/// 언어 옵션 구조체
struct LanguageOption: Identifiable, Equatable {
    let id = UUID()
    let code: String
    let name: String
    let englishName: String
}

// MARK: - String Extension
extension String {
    /// 문자열을 현재 선택된 언어로 번역
    /// 사용 예: "common.ok".localized
    var localized: String {
        return LocalizationManager.shared.localizedString(for: self)
    }

    /// 특정 Bundle에서 문자열 번역
    func localized(bundle: Bundle) -> String {
        return NSLocalizedString(self, bundle: bundle, comment: "")
    }
}

// MARK: - Text Extension
extension Text {
    /// LocalizedStringKey를 사용하여 Text 생성
    /// 사용 예: Text(localized: "common.ok")
    init(localized key: String) {
        let bundle = LocalizationManager.shared.getCurrentBundle()
        let localizedString = NSLocalizedString(key, bundle: bundle, comment: "")
        self.init(localizedString)
    }
}

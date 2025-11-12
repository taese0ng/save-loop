# 다국어 지원 가이드 (Localization Guide)

SaveLoope 앱의 다국어 지원 시스템 사용 가이드입니다.

## 지원 언어

- 🇰🇷 한국어 (Korean) - `ko`
- 🇺🇸 영어 미국 (English - US) - `en-US`
- 🇬🇧 영어 영국 (English - UK) - `en-GB`
- 🇯🇵 일본어 (Japanese) - `ja`
- 🇨🇳 중국어 간체 (Chinese Simplified) - `zh-Hans`
- 🇹🇼 중국어 번체 (Chinese Traditional) - `zh-Hant`

## 폴더 구조

```
SaveLoope/
└── Resources/
    └── Localization/
        ├── ko.lproj/
        │   └── Localizable.strings
        ├── en-US.lproj/
        │   └── Localizable.strings
        ├── en-GB.lproj/
        │   └── Localizable.strings
        ├── ja.lproj/
        │   └── Localizable.strings
        ├── zh-Hans.lproj/
        │   └── Localizable.strings
        └── zh-Hant.lproj/
            └── Localizable.strings
```

## 사용 방법

### 1. SwiftUI Text에서 사용

```swift
// 방법 1: LocalizedStringKey 사용 (권장)
Text("common.ok")

// 방법 2: String extension 사용
Text("common.ok".localized)

// 방법 3: Text extension 사용
Text(localized: "common.ok")
```

### 2. String 변수에서 사용

```swift
let okButtonText = "common.ok".localized
let cancelButtonText = "common.cancel".localized
```

### 3. Alert 메시지에서 사용

```swift
.alert("envelope.limit_reached".localized, isPresented: $showingAlert) {
    Button("common.cancel".localized, role: .cancel) { }
    Button("subscription.view_premium".localized) {
        // 프리미엄 보기 액션
    }
} message: {
    Text("envelope.limit_message".localized)
}
```

### 4. LocalizationManager 직접 사용

```swift
let localizedText = LocalizationManager.shared.localizedString(for: "common.ok")
```

## 번역 키 네이밍 규칙

번역 키는 다음과 같은 형식을 따릅니다:

```
{섹션}.{세부항목}[.{추가설명}]
```

### 예시

- `common.ok` - 공통 섹션의 OK 버튼
- `home.no_envelopes` - 홈 섹션의 빈 상태 메시지
- `envelope.type.oneTime` - 봉투 섹션의 타입 중 일회성
- `settings.cloud_sync.enable` - 설정 섹션의 클라우드 동기화 활성화

## 번역 키 카테고리

### Common (공통)
- 버튼: `common.ok`, `common.cancel`, `common.save`, `common.delete`
- 액션: `common.edit`, `common.add`, `common.done`, `common.close`
- 상태: `common.error`, `common.success`, `common.loading`

### Tabs (탭)
- `tab.home`, `tab.calendar`, `tab.settings`

### Home (홈)
- `home.title`, `home.no_envelopes`, `home.add_envelope`
- `home.empty_state.title`, `home.empty_state.description`

### Envelope (봉투)
- 기본: `envelope.name`, `envelope.budget`, `envelope.income`, `envelope.spent`
- 타입: `envelope.type.oneTime`, `envelope.type.recurring`
- 액션: `envelope.create`, `envelope.edit`, `envelope.delete`

### Transaction (거래)
- 기본: `transaction.amount`, `transaction.note`, `transaction.date`
- 타입: `transaction.type.income`, `transaction.type.expense`
- 액션: `transaction.add`, `transaction.edit`, `transaction.delete`

### Balance (잔액)
- `balance.add_income`, `balance.add_expense`
- `balance.total_income`, `balance.total_expense`, `balance.net_balance`

### Calendar (캘린더)
- `calendar.title`, `calendar.today`, `calendar.month_summary`
- `calendar.no_transactions`

### Settings (설정)
- 일반: `settings.title`, `settings.currency`, `settings.language`
- 클라우드: `settings.cloud_sync`, `settings.cloud_sync.enable`
- 데이터: `settings.data`, `settings.reset_data`
- 개발자: `settings.developer_mode`, `settings.developer_mode.enabled`

### Subscription (구독)
- `subscription.title`, `subscription.view_premium`, `subscription.upgrade`
- 플랜: `subscription.free_plan`, `subscription.premium_plan`
- 기간: `subscription.monthly`, `subscription.yearly`

### Alerts (알림)
- `alert.app_restart_required`, `alert.cloud_unavailable`
- `alert.cloud_sync_enabled`, `alert.cloud_sync_disabled`

### Errors (오류)
- `error.unknown`, `error.save_failed`, `error.load_failed`
- `error.delete_failed`, `error.network`

## 새 번역 추가하기

1. 해당하는 카테고리 찾기 또는 새 카테고리 추가
2. 모든 언어 파일에 동일한 키로 번역 추가
3. 키 네이밍 규칙 준수

### 예시: 새 번역 추가

```strings
// ko.lproj/Localizable.strings
"home.total_balance" = "전체 잔액";

// en-US.lproj/Localizable.strings
"home.total_balance" = "Total Balance";

// ja.lproj/Localizable.strings
"home.total_balance" = "総残高";

// zh-Hans.lproj/Localizable.strings
"home.total_balance" = "总余额";

// zh-Hant.lproj/Localizable.strings
"home.total_balance" = "總餘額";
```

## 동적 언어 변경

앱 실행 중 언어를 변경하려면:

```swift
LocalizationManager.shared.changeLanguage(to: "ja")
```

## Xcode 프로젝트 설정

### 1. Localization 파일을 프로젝트에 추가

1. Xcode에서 프로젝트 열기
2. File → Add Files to "SaveLoope"
3. `SaveLoope/Resources/Localization` 폴더 선택
4. "Create folder references" 선택
5. Add 클릭

### 2. 프로젝트 설정에서 Localization 활성화

1. 프로젝트 네비게이터에서 프로젝트 파일 선택
2. PROJECT 섹션에서 프로젝트 선택
3. Info 탭 선택
4. Localizations 섹션에서 + 버튼 클릭
5. 각 언어 추가: Korean, English (US), English (UK), Japanese, Chinese (Simplified), Chinese (Traditional)

### 3. Info.plist 설정

`CFBundleLocalizations` 키에 지원 언어 추가:

```xml
<key>CFBundleLocalizations</key>
<array>
    <string>ko</string>
    <string>en-US</string>
    <string>en-GB</string>
    <string>ja</string>
    <string>zh-Hans</string>
    <string>zh-Hant</string>
</array>
```

## 테스트

### 시뮬레이터에서 언어 변경

1. 시뮬레이터 실행
2. Settings → General → Language & Region
3. 원하는 언어 선택
4. 앱 재시작

### 코드로 테스트

```swift
// 미리보기에서 특정 언어로 테스트
#Preview {
    HomeView()
        .environment(\.locale, .init(identifier: "ja"))
}
```

## 주의사항

1. **번역 누락 방지**: 새 키를 추가할 때는 모든 언어 파일에 추가해야 합니다.
2. **키 일관성**: 모든 언어 파일에서 동일한 키를 사용해야 합니다.
3. **문맥 고려**: 단순 직역보다는 각 언어의 문화와 관습을 고려한 번역이 필요합니다.
4. **UI 레이아웃**: 긴 번역 텍스트로 인한 레이아웃 깨짐에 주의합니다.
5. **날짜/숫자 포맷**: 언어별로 적절한 포맷터를 사용합니다.

## 문제 해결

### 번역이 적용되지 않을 때

1. Xcode에서 Clean Build Folder (Cmd + Shift + K)
2. 앱 재빌드 및 재실행
3. 시뮬레이터 리셋

### 번역 키를 찾을 수 없다는 오류

1. 모든 언어 파일에 해당 키가 있는지 확인
2. 키 이름의 오타 확인
3. Localizable.strings 파일 형식 확인 (UTF-8 인코딩)

## 기여 가이드

새로운 번역을 추가하거나 기존 번역을 개선할 때:

1. 모든 언어 파일 업데이트
2. 키 네이밍 규칙 준수
3. 테스트 완료 후 커밋
4. 커밋 메시지에 추가/변경된 번역 키 명시

---

## 참고 자료

- [Apple Localization Guide](https://developer.apple.com/localization/)
- [SwiftUI Localization](https://developer.apple.com/documentation/swiftui/localization)
- [NSLocalizedString](https://developer.apple.com/documentation/foundation/nslocalizedstring)

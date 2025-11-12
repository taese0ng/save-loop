# Xcode 프로젝트 다국어 설정 가이드

SaveLoope 프로젝트에 다국어 지원을 완전히 활성화하기 위한 Xcode 설정 가이드입니다.

## 1단계: Localization 파일을 Xcode 프로젝트에 추가

### 방법 1: Finder를 통한 추가 (권장)

1. **Xcode에서 프로젝트 열기**
   - SaveLoope.xcodeproj 파일 더블클릭

2. **Localization 폴더 추가**
   - Xcode 왼쪽 네비게이터에서 `SaveLoope` 그룹 우클릭
   - "Add Files to 'SaveLoope'..." 선택
   - `SaveLoope/Resources/Localization` 폴더 선택
   - **중요**: "Create folder references" 선택 (Create groups 아님)
   - "Add" 버튼 클릭

3. **파일 추가 확인**
   - Xcode 네비게이터에서 Resources/Localization 폴더 확인
   - 각 .lproj 폴더와 Localizable.strings 파일 확인

### 방법 2: 파일별 개별 추가

각 언어별 Localizable.strings 파일을 개별적으로 추가:

1. Xcode에서 File → Add Files to "SaveLoope"
2. 각 .lproj 폴더 내의 Localizable.strings 파일 선택
3. 모든 언어에 대해 반복

## 2단계: 프로젝트에 Localization 언어 추가

1. **프로젝트 설정 열기**
   - Xcode 네비게이터에서 프로젝트 파일 (파란 아이콘) 클릭
   - PROJECT 섹션에서 "SaveLoope" 선택

2. **Info 탭 선택**
   - 상단 탭에서 "Info" 클릭

3. **Localizations 섹션 찾기**
   - "Localizations" 섹션으로 스크롤

4. **언어 추가**
   - "+" 버튼 클릭
   - 다음 언어들을 순서대로 추가:
     - Korean (한국어)
     - English (United States)
     - English (United Kingdom)
     - Japanese (일본어)
     - Chinese, Simplified (중국어 간체)
     - Chinese, Traditional (중국어 번체)

5. **각 언어 추가 시 파일 선택**
   - 언어 추가 시 대화상자가 나타나면
   - 해당 언어의 Localizable.strings 파일 체크
   - "Finish" 클릭

## 3단계: Info.plist 설정

1. **Info.plist 파일 열기**
   - Xcode 네비게이터에서 `Info.plist` 파일 찾기 및 클릭

2. **지원 언어 목록 추가**
   - 마우스 우클릭 → "Add Row"
   - Key: `CFBundleLocalizations`
   - Type: `Array`

3. **언어 코드 추가**
   - CFBundleLocalizations 왼쪽 화살표 클릭하여 확장
   - 각 Item에 다음 값 입력:
     ```
     Item 0: ko
     Item 1: en-US
     Item 2: en-GB
     Item 3: ja
     Item 4: zh-Hans
     Item 5: zh-Hant
     ```

4. **기본 언어 설정 (선택사항)**
   - Key: `CFBundleDevelopmentRegion`
   - Type: `String`
   - Value: `ko` (한국어를 기본으로 설정)

## 4단계: LocalizationManager 파일 추가

1. **Core/Services 그룹 찾기**
   - Xcode 네비게이터에서 `SaveLoope/Core/Services` 찾기

2. **LocalizationManager.swift 추가**
   - Core/Services 그룹 우클릭
   - "Add Files to 'SaveLoope'..."
   - `LocalizationManager.swift` 파일 선택
   - "Create groups" 선택
   - "Add" 클릭

## 5단계: 빌드 및 테스트

### Clean Build

1. **Clean Build Folder**
   - 메뉴: Product → Clean Build Folder
   - 단축키: Cmd + Shift + K

2. **프로젝트 빌드**
   - 메뉴: Product → Build
   - 단축키: Cmd + B

### 언어별 테스트

1. **시뮬레이터 실행**
   - 원하는 디바이스 선택
   - 메뉴: Product → Run
   - 단축키: Cmd + R

2. **언어 변경 테스트**
   - 시뮬레이터에서 Settings 앱 열기
   - General → Language & Region
   - "Add Language..." 선택
   - 테스트할 언어 선택
   - 앱 재시작

3. **각 언어별 확인**
   - UI 텍스트가 올바르게 번역되는지 확인
   - 레이아웃이 깨지지 않는지 확인
   - 긴 텍스트가 잘려 보이지 않는지 확인

## 6단계: 런타임 언어 변경 테스트 (선택사항)

앱 내에서 언어를 변경하는 기능을 추가하려면:

1. **설정 화면에 언어 선택 옵션 추가**
   ```swift
   NavigationLink {
       LanguageSelectionView()
   } label: {
       HStack {
           Text("settings.language")
           Spacer()
           Text(LocalizationManager.shared.currentLanguage)
               .foregroundColor(.secondary)
       }
   }
   ```

2. **언어 선택 뷰 생성**
   ```swift
   struct LanguageSelectionView: View {
       @ObservedObject var localizationManager = LocalizationManager.shared

       var body: some View {
           List(LocalizationManager.supportedLanguages) { language in
               Button {
                   localizationManager.changeLanguage(to: language.code)
               } label: {
                   HStack {
                       Text(language.name)
                       Spacer()
                       if localizationManager.currentLanguage == language.code {
                           Image(systemName: "checkmark")
                       }
                   }
               }
           }
           .navigationTitle("settings.language")
       }
   }
   ```

## 문제 해결

### 문제 1: 번역이 적용되지 않음

**해결 방법:**
1. Clean Build Folder (Cmd + Shift + K)
2. Derived Data 삭제
   - Xcode → Preferences → Locations
   - Derived Data 경로 옆 화살표 클릭
   - DerivedData 폴더에서 SaveLoope 관련 폴더 삭제
3. 프로젝트 재빌드

### 문제 2: Localizable.strings 파일을 찾을 수 없음

**해결 방법:**
1. 파일이 Target에 추가되었는지 확인
   - 파일 선택
   - 우측 Inspector에서 "Target Membership" 확인
   - SaveLoope 체크박스 활성화
2. Build Phases 확인
   - PROJECT 섹션에서 SaveLoope 선택
   - "Build Phases" 탭
   - "Copy Bundle Resources"에 .strings 파일들이 있는지 확인

### 문제 3: 특정 언어만 작동하지 않음

**해결 방법:**
1. 해당 언어의 Localizable.strings 파일 인코딩 확인
   - 파일 선택
   - 우측 Inspector에서 "Text Encoding" 확인
   - UTF-8 선택
2. 파일 형식 확인
   - Key-Value 쌍이 올바른지 확인
   - 문자열이 따옴표로 제대로 감싸져 있는지 확인
   - 세미콜론(;)이 각 줄 끝에 있는지 확인

### 문제 4: UI 레이아웃 깨짐

**해결 방법:**
1. 긴 텍스트를 고려한 UI 설계
   ```swift
   Text("long.text.key")
       .lineLimit(2)
       .minimumScaleFactor(0.8)
   ```
2. 동적 타입 크기 지원
   ```swift
   Text("text.key")
       .font(.system(size: 17, weight: .regular, design: .default))
       .dynamicTypeSize(...aDynamicTypeSize)
   ```

## 체크리스트

다국어 지원 구현 완료를 위한 체크리스트:

- [ ] 모든 .lproj 폴더가 Xcode 프로젝트에 추가됨
- [ ] Localizable.strings 파일들이 Target에 포함됨
- [ ] Info.plist에 CFBundleLocalizations 설정 완료
- [ ] LocalizationManager.swift 파일 추가 및 빌드 성공
- [ ] 각 언어별 시뮬레이터 테스트 완료
- [ ] UI 레이아웃 깨짐 없음 확인
- [ ] 모든 텍스트가 번역 키로 변경됨 (하드코딩된 텍스트 제거)
- [ ] 날짜/숫자 포맷이 locale에 맞게 설정됨
- [ ] 실제 디바이스 테스트 완료 (선택사항)

## 다음 단계

1. **하드코딩된 텍스트 변경**
   - 기존 View 파일들에서 하드코딩된 한국어 텍스트를 번역 키로 변경
   - 예: `Text("확인")` → `Text("common.ok")`

2. **번역 검증**
   - 원어민 또는 전문 번역가에게 번역 검토 의뢰
   - 문맥에 맞는 자연스러운 번역인지 확인

3. **추가 번역 키 작성**
   - 현재 누락된 화면의 텍스트 번역 추가
   - 새 기능 추가 시 번역 키 함께 작성

4. **자동화 스크립트 작성** (선택사항)
   - 번역 누락 감지 스크립트
   - 번역 키 일관성 검사 스크립트

---

## 참고 자료

- [Xcode Localization Guide](https://developer.apple.com/documentation/xcode/localization)
- [Adding Support for Languages and Regions](https://developer.apple.com/documentation/xcode/adding-support-for-languages-and-regions)
- [Localizing Strings in Your App](https://developer.apple.com/documentation/xcode/localizing-strings-in-your-app)

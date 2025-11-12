//
//  LocalizationExample.swift
//  SaveLoope
//
//  다국어 지원 사용 예제
//  실제 사용 방법을 보여주는 샘플 코드입니다.
//

import SwiftUI

/// 다국어 지원 사용 예제 뷰
struct LocalizationExampleView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var showingAlert = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 기본 사용법
                Section(header: Text("기본 사용법")) {
                    // 방법 1: LocalizedStringKey 사용 (가장 간단)
                    Text("common.ok")

                    // 방법 2: String extension 사용
                    Text("common.cancel".localized)

                    // 방법 3: Text extension 사용
                    Text(localized: "common.save")
                }

                // MARK: - 버튼에서 사용
                Section(header: Text("버튼에서 사용")) {
                    Button("common.add".localized) {
                        print("추가 버튼 클릭")
                    }

                    Button {
                        print("삭제 버튼 클릭")
                    } label: {
                        Text("common.delete")
                            .foregroundColor(.red)
                    }
                }

                // MARK: - 변수에 할당
                Section(header: Text("변수에 할당")) {
                    let okText = "common.ok".localized
                    let cancelText = "common.cancel".localized

                    Text("OK: \(okText)")
                    Text("Cancel: \(cancelText)")
                }

                // MARK: - Alert에서 사용
                Section(header: Text("Alert에서 사용")) {
                    Button("Alert 표시") {
                        showingAlert = true
                    }
                }

                // MARK: - 언어 선택
                Section(header: Text("언어 선택")) {
                    ForEach(LocalizationManager.supportedLanguages) { language in
                        Button {
                            localizationManager.changeLanguage(to: language.code)
                        } label: {
                            HStack {
                                Text(language.name)
                                Spacer()
                                if localizationManager.currentLanguage == language.code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                // MARK: - 현재 언어 정보
                Section(header: Text("현재 언어 정보")) {
                    Text("현재 언어: \(localizationManager.currentLanguage)")
                    Text("시스템 언어: \(Locale.preferredLanguages.first ?? "Unknown")")
                }
            }
            .navigationTitle("다국어 지원 예제")
            .alert("alert.app_restart_required".localized, isPresented: $showingAlert) {
                Button("common.ok".localized, role: .cancel) { }
            } message: {
                Text("alert.cloud_sync_enabled".localized)
            }
        }
    }
}

// MARK: - 실제 사용 예제들

/// 홈 화면에서의 사용 예제
struct HomeViewLocalizationExample: View {
    var body: some View {
        VStack(spacing: 20) {
            // 제목
            Text("home.title")
                .font(.largeTitle)
                .fontWeight(.bold)

            // 빈 상태 메시지
            Text("home.no_envelopes")
                .font(.body)
                .foregroundColor(.secondary)

            // 버튼
            Button("home.add_envelope".localized) {
                // 봉투 추가 액션
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

/// 설정 화면에서의 사용 예제
struct SettingsViewLocalizationExample: View {
    @State private var showingResetAlert = false

    var body: some View {
        List {
            Section {
                NavigationLink {
                    Text("통화 설정")
                } label: {
                    HStack {
                        Text("settings.currency")
                        Spacer()
                        Text("KRW")
                            .foregroundColor(.secondary)
                    }
                }

                NavigationLink {
                    Text("언어 설정")
                } label: {
                    HStack {
                        Text("settings.language")
                        Spacer()
                        Text("한국어")
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    Text("settings.reset_data")
                }
            }
        }
        .navigationTitle("settings.title")
        .alert("settings.reset_data".localized, isPresented: $showingResetAlert) {
            Button("common.cancel".localized, role: .cancel) { }
            Button("common.delete".localized, role: .destructive) {
                // 데이터 리셋 액션
            }
        } message: {
            Text("settings.reset_data_confirm")
        }
    }
}

/// 봉투 화면에서의 사용 예제
struct EnvelopeViewLocalizationExample: View {
    var body: some View {
        Form {
            Section(header: Text("envelope.name")) {
                TextField("envelope.name".localized, text: .constant("식비"))
            }

            Section(header: Text("envelope.budget")) {
                TextField("envelope.amount".localized, text: .constant("500000"))
            }

            Section(header: Text("envelope.type")) {
                Picker("envelope.type".localized, selection: .constant(0)) {
                    Text("envelope.type.oneTime").tag(0)
                    Text("envelope.type.recurring").tag(1)
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button("envelope.create".localized) {
                    // 봉투 생성 액션
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("envelope.create")
    }
}

/// 거래 화면에서의 사용 예제
struct TransactionViewLocalizationExample: View {
    @State private var transactionType = 0

    var body: some View {
        Form {
            Section(header: Text("transaction.type")) {
                Picker("transaction.type".localized, selection: $transactionType) {
                    Text("transaction.type.income").tag(0)
                    Text("transaction.type.expense").tag(1)
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("transaction.amount")) {
                TextField("transaction.amount".localized, text: .constant("10000"))
                    .keyboardType(.numberPad)
            }

            Section(header: Text("transaction.note")) {
                TextEditor(text: .constant(""))
                    .frame(height: 100)
            }

            Section {
                Button("transaction.add".localized) {
                    // 거래 추가 액션
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("transaction.add")
    }
}

// MARK: - Preview

#Preview("다국어 지원 예제") {
    LocalizationExampleView()
}

#Preview("홈 화면 예제") {
    HomeViewLocalizationExample()
}

#Preview("설정 화면 예제") {
    NavigationStack {
        SettingsViewLocalizationExample()
    }
}

#Preview("봉투 화면 예제") {
    NavigationStack {
        EnvelopeViewLocalizationExample()
    }
}

#Preview("거래 화면 예제") {
    NavigationStack {
        TransactionViewLocalizationExample()
    }
}

#Preview("일본어 환경") {
    LocalizationExampleView()
        .environment(\.locale, .init(identifier: "ja"))
}

#Preview("중국어 간체 환경") {
    LocalizationExampleView()
        .environment(\.locale, .init(identifier: "zh-Hans"))
}

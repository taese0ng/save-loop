import SwiftUI

public struct LabeledNumberField: View {
    let label: String
    @Binding var value: Double?
    var placeholder: String = ""
    var required: Bool = false
    var prefix: String? = nil
    @State private var displayText: String = ""
    @State private var isUserInputting: Bool = false
    @State private var isProcessing: Bool = false

    private var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    public init(label: String, value: Binding<Double?>, placeholder: String = "", required: Bool = false, prefix: String? = nil) {
        self.label = label
        self._value = value
        self.placeholder = placeholder
        self.required = required
        self.prefix = prefix

        // 초기값이 있으면 표시 형식으로 변환
        if let initialValue = value.wrappedValue {
            _displayText = State(initialValue: Self.formatDisplayText(initialValue))
        }
    }

    // Double 값을 표시 텍스트로 변환 (100.0 → "100", 100.5 → "100.5")
    private static func formatDisplayText(_ doubleValue: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0

        // 소수점 이하가 0이면 정수로 표시
        if doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
            formatter.maximumFractionDigits = 0
        }

        return formatter.string(from: NSNumber(value: doubleValue)) ?? "\(doubleValue)"
    }

    private func formatDisplayText(_ doubleValue: Double) -> String {
        Self.formatDisplayText(doubleValue)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 3){
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
                
                if required {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
            }
            
            HStack(spacing: 4) {
                TextField(placeholder, text: $displayText)
                    .keyboardType(.decimalPad)
                    .textContentType(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: displayText) { oldValue, newValue in
                        guard !isProcessing else { return }

                        isUserInputting = true
                        isProcessing = true

                        // 콤마 제거
                        let cleanValue = newValue.replacingOccurrences(of: ",", with: "")

                        // 빈 값이면 nil
                        if cleanValue.isEmpty {
                            value = nil
                            isUserInputting = false
                            isProcessing = false
                            return
                        }

                        // 소수점이 2개 이상이면 이전 값으로 복원
                        let dotCount = cleanValue.filter { $0 == "." }.count
                        if dotCount > 1 {
                            displayText = oldValue
                            isUserInputting = false
                            isProcessing = false
                            return
                        }

                        // 소수점으로 시작하면 허용 안 함 (예: ".5")
                        if cleanValue.hasPrefix(".") {
                            displayText = oldValue
                            isUserInputting = false
                            isProcessing = false
                            return
                        }

                        // "123." 처럼 소수점으로 끝나는 경우
                        if cleanValue.hasSuffix(".") {
                            let withoutDot = cleanValue.replacingOccurrences(of: ".", with: "")
                            if let intPart = Int(withoutDot) {
                                // 값 저장 (그대로)
                                value = Double(intPart)
                                // 천 단위 구분자 추가하고 소수점 유지
                                let formattedInt = numberFormatter.string(from: NSNumber(value: intPart)) ?? withoutDot
                                let newText = "\(formattedInt)."
                                if newText != displayText {
                                    displayText = newText
                                }
                            } else if withoutDot.isEmpty {
                                // "." 만 입력한 경우 허용 안 함
                                displayText = oldValue
                            }
                        }
                        // 숫자 파싱 가능한 경우
                        else if let doubleValue = Double(cleanValue) {
                            // 그대로 저장 (100.01 → 100.01)
                            value = doubleValue

                            // 천 단위 구분자 추가
                            if !cleanValue.contains(".") {
                                // 정수인 경우
                                if let intValue = Int(cleanValue) {
                                    let formatted = numberFormatter.string(from: NSNumber(value: intValue)) ?? cleanValue
                                    if formatted != displayText {
                                        displayText = formatted
                                    }
                                }
                            } else {
                                // 소수점이 있는 경우
                                let parts = cleanValue.split(separator: ".")
                                if parts.count == 2 {
                                    let intPartStr = String(parts[0])
                                    let decimalPart = String(parts[1])

                                    // 소수점 2자리까지만 허용
                                    if decimalPart.count > 2 {
                                        let limitedDecimal = String(decimalPart.prefix(2))
                                        if let intPart = Int(intPartStr) {
                                            let formattedInt = numberFormatter.string(from: NSNumber(value: intPart)) ?? intPartStr
                                            let newText = "\(formattedInt).\(limitedDecimal)"
                                            if newText != displayText {
                                                displayText = newText
                                            }
                                        }
                                    } else {
                                        // 소수점 2자리 이하: 정수 부분에만 천 단위 구분자
                                        if let intPart = Int(intPartStr), intPart >= 1000 {
                                            let formattedInt = numberFormatter.string(from: NSNumber(value: intPart)) ?? intPartStr
                                            let newText = "\(formattedInt).\(decimalPart)"
                                            if newText != displayText {
                                                displayText = newText
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            // 유효하지 않은 입력
                            displayText = oldValue
                        }

                        isUserInputting = false
                        isProcessing = false
                    }
                
                if let prefix = prefix {
                    Text(prefix)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 4)
        }
        .onChange(of: value) { oldValue, newValue in
            // 사용자가 입력 중이 아닐 때만 displayText 업데이트
            guard !isUserInputting else { return }

            if let newValue = newValue {
                displayText = formatDisplayText(newValue)
            } else {
                displayText = ""
            }
        }
    }
}

#Preview {
    @Previewable @State var sampleValue: Double? = 1000.5
    VStack(spacing: 20) {
        LabeledNumberField(label: "금액", value: $sampleValue, required: true, prefix: "원")
        LabeledNumberField(label: "수량", value: $sampleValue, required: true)
    }
}

import SwiftUI

public struct LabeledNumberField: View {
    let label: String
    @Binding var value: Int?
    var placeholder: String = ""
    var required: Bool = false
    var prefix: String? = nil
    @State private var displayText: String = ""
    @State private var isUserInputting: Bool = false // 사용자가 입력 중인지 추적
    @State private var isProcessing: Bool = false // onChange 내부 처리 중인지 추적
    
    private var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    public init(label: String, value: Binding<Int?>, placeholder: String = "", required: Bool = false, prefix: String? = nil) {
        self.label = label
        self._value = value
        self.placeholder = placeholder
        self.required = required
        self.prefix = prefix
        // Initialize displayText with formatted value if it exists
        if let initialValue = value.wrappedValue {
            // 기존 값은 센트 단위로 저장되어 있다고 가정하고 원 단위로 변환하여 표시
            let dollarValue = Double(initialValue) / 100.0
            _displayText = State(initialValue: numberFormatter.string(from: NSNumber(value: dollarValue)) ?? "")
        }
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
                        // 무한 루프 방지
                        guard !isProcessing else { return }
                        
                        isUserInputting = true
                        isProcessing = true
                        
                        // Remove all commas from the input
                        let cleanValue = newValue.replacingOccurrences(of: ",", with: "")
                        
                        // If the input is empty, set value to nil
                        if cleanValue.isEmpty {
                            value = nil
                            isUserInputting = false
                            isProcessing = false
                            return
                        }
                        
                        // 여러 개의 소수점이 있으면 이전 값으로 복원
                        let dotCount = cleanValue.filter { $0 == "." }.count
                        if dotCount > 1 {
                            displayText = oldValue
                            isUserInputting = false
                            isProcessing = false
                            return
                        }
                        
                        // 값 계산 및 저장 (표시는 최소한으로 변경)
                        if cleanValue.hasSuffix(".") {
                            // "123." 같은 경우 - 소수점 입력 중
                            let withoutDot = cleanValue.replacingOccurrences(of: ".", with: "")
                            if let intPart = Int(withoutDot) {
                                value = intPart * 100
                                // 천 단위 구분자 추가
                                let formattedInt = numberFormatter.string(from: NSNumber(value: intPart)) ?? withoutDot
                                let newText = "\(formattedInt)."
                                if newText != displayText {
                                    displayText = newText
                                }
                            } else if withoutDot.isEmpty {
                                // "."만 입력한 경우 - 허용하지 않음
                                displayText = oldValue
                            } else {
                                displayText = oldValue
                            }
                        } else if let doubleValue = Double(cleanValue) {
                            // Double로 파싱 가능한 경우
                            // 소수점으로 시작하는 경우 (예: ".5")는 허용하지 않음
                            if cleanValue.hasPrefix(".") {
                                displayText = oldValue
                            } else {
                                let cents = Int(round(doubleValue * 100))
                                value = cents
                                
                                // 천 단위 구분자 추가 (정수 부분만)
                                if !cleanValue.contains(".") {
                                    // 정수인 경우
                                    if let intValue = Int(cleanValue) {
                                        let formatted = numberFormatter.string(from: NSNumber(value: intValue)) ?? cleanValue
                                        if formatted != displayText {
                                            displayText = formatted
                                        }
                                    }
                                } else {
                                    // 소수점이 있는 경우 - 사용자 입력을 최대한 유지
                                    let parts = cleanValue.split(separator: ".")
                                    if parts.count == 2 {
                                        let intPartStr = String(parts[0])
                                        let decimalPart = String(parts[1])
                                        
                                        // 정수 부분이 비어있으면 허용하지 않음
                                        if intPartStr.isEmpty {
                                            displayText = oldValue
                                        } else {
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
                                                // 소수점이 2자리 이하인 경우 - 정수 부분에만 천 단위 구분자 추가
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
                                }
                            }
                        } else {
                            // 유효하지 않은 입력
                            displayText = oldValue
                        }
                        
                        // 입력 처리 완료
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isUserInputting = false
                            isProcessing = false
                        }
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
                // 기존 값은 센트 단위이므로 원 단위로 변환하여 표시
                let dollarValue = Double(newValue) / 100.0
                displayText = numberFormatter.string(from: NSNumber(value: dollarValue)) ?? ""
            } else {
                displayText = ""
            }
        }
    }
}

#Preview {
    @Previewable @State var sampleValue:Int? = 1000
    VStack(spacing: 20) {
        LabeledNumberField(label: "금액", value: $sampleValue, required: true, prefix: "원")
        LabeledNumberField(label: "수량", value: $sampleValue, required: true)
    }
}

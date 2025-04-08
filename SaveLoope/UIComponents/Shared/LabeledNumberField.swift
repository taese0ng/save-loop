import SwiftUI

public struct LabeledNumberField: View {
    let label: String
    @Binding var value: Int?
    var placeholder: String = ""
    var required: Bool = false
    var prefix: String? = nil
    @State private var displayText: String = ""
    
    private var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
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
            _displayText = State(initialValue: numberFormatter.string(from: NSNumber(value: initialValue)) ?? "")
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
                    .textContentType(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: displayText) { oldValue, newValue in
                        // Remove all commas from the input
                        let cleanValue = newValue.replacingOccurrences(of: ",", with: "")
                        
                        // If the input is empty, set value to nil
                        if cleanValue.isEmpty {
                            value = nil
                            return
                        }
                        
                        // Try to convert the clean string to an integer
                        if let intValue = Int(cleanValue) {
                            value = intValue
                            // Format the number with commas
                            displayText = numberFormatter.string(from: NSNumber(value: intValue)) ?? cleanValue
                        } else {
                            // If the input is not a valid number, revert to the previous value
                            if let currentValue = value {
                                displayText = numberFormatter.string(from: NSNumber(value: currentValue)) ?? ""
                            } else {
                                displayText = ""
                            }
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
            if let newValue = newValue {
                displayText = numberFormatter.string(from: NSNumber(value: newValue)) ?? ""
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

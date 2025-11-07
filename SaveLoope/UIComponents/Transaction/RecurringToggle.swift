import SwiftUI

struct RecurringToggle: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(label, isOn: $isOn)
            .padding(.vertical, 8)
            .tint(.blue)
    }
}

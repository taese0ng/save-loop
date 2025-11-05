import SwiftUI

struct CloseButton: View {
    let onDismiss: () -> Void
    
    var body: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .foregroundColor(.gray)
        }
    }
}

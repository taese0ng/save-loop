import SwiftUI

struct BackButton: View {
    let onDismiss: () -> Void
    
    var body: some View {
        Button(action: onDismiss) {
            Image(systemName: "chevron.left")
                .foregroundColor(.black)
        }
    }
}

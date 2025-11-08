import SwiftUI

struct EditButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
            }
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .fixedSize()
    }
}


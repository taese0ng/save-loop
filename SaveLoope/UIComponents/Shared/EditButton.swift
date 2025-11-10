import SwiftUI

struct EditButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 38, height: 38)

                Image(systemName: "square.and.pencil")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("PrimaryText"))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .fixedSize()
    }
}


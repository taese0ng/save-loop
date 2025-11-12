import SwiftUI

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title.localized)
                .foregroundColor(Color("SecondaryText"))
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

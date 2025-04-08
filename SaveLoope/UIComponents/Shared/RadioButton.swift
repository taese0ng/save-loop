import SwiftUI

struct RadioButtonGroup<T: Identifiable>: View {
    let title: String
    let items: [T]
    let selectedItem: T?
    let isRecurring: (T) -> Bool
    let itemTitle: (T) -> String
    let onSelection: (T) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 15) {
                ForEach(items) { item in
                    RadioButton(
                        title: itemTitle(item),
                        isRecurring: isRecurring(item),
                        isSelected: selectedItem?.id == item.id
                    ) {
                        onSelection(item)
                    }
                }
            }
        }
    }
}

struct RadioButton: View {
    let title: String
    let isRecurring: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                HStack{
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .fill(isSelected ? Color.blue : Color.clear)
                                .frame(width: 12, height: 12)
                        )
                    Text(title)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                if isRecurring {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
        }
    }
}

#Preview {
    struct PreviewItem: Identifiable {
        let id = UUID()
        let name: String
        let isRecurring: Bool
    }
    
    let items = [
        PreviewItem(name: "식비", isRecurring: true),
        PreviewItem(name: "교통비", isRecurring: false),
        PreviewItem(name: "문화생활", isRecurring: true)
    ]
    
    return RadioButtonGroup(
        title: "지출 봉투",
        items: items,
        selectedItem: items[0],
        isRecurring: { $0.isRecurring },
        itemTitle: { $0.name },
        onSelection: { _ in }
    )
    .padding()
}

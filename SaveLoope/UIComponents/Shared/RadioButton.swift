import SwiftUI

struct RadioButtonGroup<T: Identifiable>: View {
    let title: String
    let items: [T]
    let selectedItem: T?
    let envelopeType: (T) -> EnvelopeType
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
                        envelopeType: envelopeType(item),
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
    let envelopeType: EnvelopeType
    let isSelected: Bool
    let action: () -> Void
    
    // 봉투 타입에 따른 색상
    private var buttonColor: Color {
        switch envelopeType {
        case .persistent:
            return .purple
        case .recurring:
            return .blue
        case .normal:
            return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                HStack{
                    Circle()
                        .stroke(buttonColor, lineWidth: 2)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .fill(isSelected ? buttonColor : Color.clear)
                                .frame(width: 12, height: 12)
                        )
                    Text(title)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                // 지속형 봉투 아이콘
                if envelopeType == .persistent {
                    Image(systemName: "infinity")
                        .foregroundColor(.purple)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                // 반복 봉투 아이콘
                if envelopeType == .recurring {
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
        let envelopeType: EnvelopeType
    }
    
    let items = [
        PreviewItem(name: "일반 봉투", envelopeType: .normal),
        PreviewItem(name: "반복 봉투", envelopeType: .recurring),
        PreviewItem(name: "지속 봉투", envelopeType: .persistent)
    ]
    
    return RadioButtonGroup(
        title: "지출 봉투",
        items: items,
        selectedItem: items[0],
        envelopeType: { $0.envelopeType },
        itemTitle: { $0.name },
        onSelection: { _ in }
    )
    .padding()
}

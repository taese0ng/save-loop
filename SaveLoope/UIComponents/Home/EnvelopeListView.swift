import SwiftUI
import SwiftData

struct EnvelopeListView: View {
    var hasNotAddButton: Bool = false
    let envelopes: [Envelope]
    let onAddEnvelope: () -> Void
    let onEnvelopeTap: (Envelope) -> Void
    
    // 플로팅 버튼 크기 상수
    private let floatingButtonSize: CGFloat = 56
    private let floatingButtonPadding: CGFloat = 20

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            List {
                ForEach(envelopes) { envelope in
                    Button(action: { onEnvelopeTap(envelope) }) {
                        EnvelopeCardView(envelope: envelope)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .padding(.horizontal)
                    .padding(.vertical, 5)
                    .listRowSeparator(.hidden)
                }
                
                // 리스트 하단 공백 (플로팅 버튼과 겹치지 않도록)
                if !hasNotAddButton {
                    Color.clear
                        .frame(height: floatingButtonSize + floatingButtonPadding)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            
            // 플로팅 버튼 (우측 하단)
            if !hasNotAddButton {
                Button(action: onAddEnvelope) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: floatingButtonSize, height: floatingButtonSize)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, floatingButtonPadding)
                .padding(.bottom, floatingButtonPadding)
            }
        }
    }
}

#Preview {
    EnvelopeListView(
        envelopes: [
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
            Envelope(name: "생활비", budget: 1000000, spent: 400000),
        ],
        onAddEnvelope: { print("add") },
        onEnvelopeTap: { _ in print("tap") }
    )
}

import SwiftUI
import SwiftData

struct EnvelopeListView: View {
    var hasNotAddButton: Bool = false
    let envelopes: [Envelope]
    let onAddEnvelope: () -> Void
    let onEnvelopeTap: (Envelope) -> Void

    var body: some View {
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
            if !hasNotAddButton {
                Section {
                    HStack{
                        AddEnvelopeButton(action: onAddEnvelope)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 10)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
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

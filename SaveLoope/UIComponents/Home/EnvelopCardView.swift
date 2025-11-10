import SwiftUI

struct EnvelopeCardView: View {
    @Bindable var envelope: Envelope
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var animatedProgress: Double = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 카테고리 이름 (ex: 생활비)
            HStack {
                Text(envelope.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryText"))

                // 지속형 봉투 아이콘
                if envelope.type == .persistent {
                    Image(systemName: "infinity")
                        .foregroundColor(.purple)
                        .font(.caption)
                        .fontWeight(.bold)
                }

                // 반복 봉투 아이콘
                if envelope.type == .recurring {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }

            // 잔액 표시
            HStack {
                Text("잔액:")
                    .font(.subheadline)
                    .foregroundColor(Color("PrimaryText"))
                Text(envelope.remaining.formattedCurrency)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryText"))
            }

            // 프로그레스 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color("Separator"))
                        .frame(height: 6)

                    Capsule()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * animatedProgress, height: 6)
                        .animation(.easeInOut(duration: 1.0), value: animatedProgress)
                }
            }
            .frame(height: 6)

        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color("CardBackground"))
        .cornerRadius(12)
        .shadow(color: Color("Separator"), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            animatedProgress = envelope.progress
        }
    }
}

struct EnvelopeCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EnvelopeCardView(envelope: Envelope(name: "일반 봉투", budget: 100000.0, spent: 10000.0))
            EnvelopeCardView(envelope: Envelope(name: "반복 봉투", budget: 100000.0, spent: 10000.0, isRecurring: true, envelopeType: .recurring))
            EnvelopeCardView(envelope: Envelope(name: "지속 봉투", budget: 100000.0, spent: 10000.0, envelopeType: .persistent))
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

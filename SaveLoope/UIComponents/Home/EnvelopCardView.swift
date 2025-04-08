import SwiftUI

struct EnvelopeCardView: View {
    @Bindable var envelope: Envelope
    @State private var animatedProgress: Double = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 카테고리 이름 (ex: 생활비)
            HStack {
                Text(envelope.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                if envelope.parentId != nil {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }

            // 잔액 표시
            HStack {
                Text("잔액:")
                    .font(.subheadline)
                    .foregroundColor(.black)
                Text("\(Int(envelope.remaining).formattedWithSeparator)원")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }

            // 프로그레스 바
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            animatedProgress = envelope.progress
        }
    }
}

// 숫자 포맷팅 (천 단위 구분)
extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

struct EnvelopeCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            EnvelopeCardView(envelope: Envelope(name: "생활비", budget: 100000, spent: 10000))
            EnvelopeCardView(envelope: Envelope(name: "반복생성", budget: 100000, spent: 10000, isRecurring: true))
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

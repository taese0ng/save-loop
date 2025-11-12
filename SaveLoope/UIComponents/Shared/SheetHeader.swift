import SwiftUI

struct SheetHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder private let trailing: () -> Trailing

    init(title: String, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color("DividerColor").opacity(1))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            ZStack {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color("PrimaryText"))

                HStack {
                    Spacer()
                    trailing()
                }
                .padding(.trailing, 12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    SheetHeader(title: "프리뷰 타이틀") {
        Button {} label: {
            Image(systemName: "xmark")
        }
    }
}


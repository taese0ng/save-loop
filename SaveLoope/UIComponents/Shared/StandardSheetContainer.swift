import SwiftUI

struct StandardSheetContainer<Content: View, Footer: View, Trailing: View>: View {
    let title: String
    var backgroundColor: Color = Color(UIColor.systemGroupedBackground)
    @ViewBuilder private let trailingAccessory: () -> Trailing
    @ViewBuilder private let content: () -> Content
    @ViewBuilder private let footer: () -> Footer

    init(
        title: String,
        backgroundColor: Color = Color(UIColor.systemGroupedBackground),
        @ViewBuilder trailingAccessory: @escaping () -> Trailing,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.trailingAccessory = trailingAccessory
        self.content = content
        self.footer = footer
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader<Trailing>(title: title, trailing: trailingAccessory)

            content()
                .frame(maxWidth: .infinity, alignment: .topLeading)

            footer()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 20)
        }
        .background(backgroundColor)
        .ignoresSafeArea()
        .presentationDragIndicator(.hidden)
    }
}

extension StandardSheetContainer where Footer == EmptyView, Trailing == EmptyView {
    init(
        title: String,
        backgroundColor: Color = Color(UIColor.systemGroupedBackground),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            title: title,
            backgroundColor: backgroundColor,
            trailingAccessory: { EmptyView() },
            content: content,
            footer: { EmptyView() }
        )
    }
}

extension StandardSheetContainer where Footer == EmptyView {
    init(
        title: String,
        backgroundColor: Color = Color(UIColor.systemGroupedBackground),
        @ViewBuilder trailingAccessory: @escaping () -> Trailing,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            title: title,
            backgroundColor: backgroundColor,
            trailingAccessory: trailingAccessory,
            content: content,
            footer: { EmptyView() }
        )
    }
}

extension StandardSheetContainer where Trailing == EmptyView {
    init(
        title: String,
        backgroundColor: Color = Color(UIColor.systemGroupedBackground),
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.init(
            title: title,
            backgroundColor: backgroundColor,
            trailingAccessory: { EmptyView() },
            content: content,
            footer: footer
        )
    }
}

#Preview {
    StandardSheetContainer(title: "샘플 시트", trailingAccessory: {
        Button {} label: {
            Image(systemName: "xmark")
        }
    }) {
        Text("콘텐츠")
            .padding()
    } footer: {
        Button("확인") { }
            .frame(maxWidth: .infinity)
            .padding()
    }
}


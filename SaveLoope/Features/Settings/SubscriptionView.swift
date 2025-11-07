import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "알림"
    @State private var showingManageSubscriptions = false

    // 한국식 날짜 포맷터
    private let koreanDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // 헤더
                        headerSection

                        // 현재 구독 상태
                        if subscriptionManager.isSubscribed {
                            currentSubscriptionSection
                        }

                        // 구독 제품 목록
                        productsSection

                        // 복원 버튼
                        restoreButton

                        // 약관 및 정보
                        termsSection
                    }
                    .padding()
                }

                // 로딩 인디케이터
                if subscriptionManager.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("프리미엄 멤버십")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .task {
                // 뷰가 나타날 때 제품 다시 로드
                if subscriptionManager.products.isEmpty {
                    await subscriptionManager.loadProducts()
                }
                // 구독 상태 업데이트 (구독 취소 감지)
                await subscriptionManager.updateSubscriptionStatus()
            }
            .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
            .onChange(of: showingManageSubscriptions) { oldValue, newValue in
                // 구독 관리 화면이 닫힐 때 상태 업데이트
                if oldValue && !newValue {
                    Task {
                        await subscriptionManager.updateSubscriptionStatus()
                    }
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("프리미엄으로 업그레이드")
                .font(.title2)
                .fontWeight(.bold)

            Text("무제한 봉투 생성과 고급 기능을 이용하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    // MARK: - Current Subscription Section
    private var currentSubscriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("현재 구독 중")
                    .font(.headline)
                Spacer()

                // 평생 이용권이 아닌 경우에만 구독 관리 버튼 표시
                if case .subscribed(let product) = subscriptionManager.subscriptionStatus,
                   product.subscription != nil {
                    Button(action: {
                        showingManageSubscriptions = true
                    }) {
                        Text("구독 관리")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }

            if case .subscribed(let product) = subscriptionManager.subscriptionStatus {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.displayName)
                                .font(.body)
                                .fontWeight(.semibold)

                            if product.subscription != nil {
                                Text("구독 활성화됨")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("평생 이용권 활성화됨")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }

                    // 구독 변경 예정 정보
                    if let info = subscriptionManager.subscriptionInfo {
                        Divider()

                        if let pendingProduct = info.pendingProduct {
                            // 다른 구독으로 변경 예정
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("구독 변경 예정")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                    Text("\(pendingProduct.displayName)으로 변경")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    if let renewalDate = info.renewalDate {
                                        Text(koreanDateFormatter.string(from: renewalDate))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        } else if info.willRenew, let renewalDate = info.renewalDate {
                            // 자동 갱신 예정
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise.circle")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("다음 결제일")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(koreanDateFormatter.string(from: renewalDate))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        } else if !info.willRenew {
                            // 자동 갱신 해제됨
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("자동 갱신 해제됨")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.orange)
                                    if let renewalDate = info.renewalDate {
                                        Text("\(koreanDateFormatter.string(from: renewalDate))까지 이용 가능")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Products Section
    private var productsSection: some View {
        VStack(spacing: 16) {
            if subscriptionManager.products.isEmpty && !subscriptionManager.isLoading {
                // 제품 로드 실패 시 빈 상태
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text("제품을 불러올 수 없습니다")
                        .font(.headline)

                    Text(subscriptionManager.errorMessage ?? "네트워크 연결을 확인해주세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("다시 시도") {
                        Task {
                            await subscriptionManager.loadProducts()
                        }
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 8)
                }
                .padding(.vertical, 40)
            } else {
                ForEach(filteredProducts, id: \.id) { product in
                    ProductCard(
                        product: product,
                        isSubscribed: subscriptionManager.isSubscribed(to: product.id),
                        isPending: subscriptionManager.subscriptionInfo?.pendingProduct?.id == product.id,
                        onPurchase: {
                            Task {
                                do {
                                    let success = try await subscriptionManager.purchase(product)
                                    if success {
                                        alertTitle = "구매 완료"
                                        alertMessage = "\(product.displayName) 구매가 완료되었습니다!"
                                        showingAlert = true
                                    }
                                } catch {
                                    alertTitle = "구매 실패"
                                    alertMessage = subscriptionManager.errorMessage ?? "구매 중 오류가 발생했습니다."
                                    showingAlert = true
                                }
                            }
                        }
                    )
                }
            }
        }
    }

    // 평생 이용권이 있으면 월간/연간 구독권 필터링
    private var filteredProducts: [Product] {
        let hasLifetime = subscriptionManager.isSubscribed(to: SubscriptionProduct.lifetime.rawValue)

        if hasLifetime {
            // 평생 이용권만 표시
            return subscriptionManager.products.filter { product in
                product.id == SubscriptionProduct.lifetime.rawValue
            }
        } else {
            // 모든 제품 표시
            return subscriptionManager.products
        }
    }

    // MARK: - Restore Button
    private var restoreButton: some View {
        Button(action: {
            Task {
                await subscriptionManager.restorePurchases()

                if subscriptionManager.isSubscribed {
                    alertTitle = "복원 완료"
                    alertMessage = "구매 내역을 복원했습니다."
                } else {
                    alertTitle = "복원 결과"
                    alertMessage = "복원할 구매 내역이 없습니다."
                }
                showingAlert = true
            }
        }) {
            Text("구매 복원")
                .font(.subheadline)
                .foregroundColor(.blue)
        }
        .padding(.top, 8)
    }

    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 8) {
            Text("• 구독은 언제든지 취소할 수 있습니다")
            Text("• 구독 취소 시 현재 기간 종료 후 자동 갱신되지 않습니다")
            Text("• 구독 갱신 24시간 전까지 자동으로 갱신됩니다")
            Text("• '구독 관리' 버튼으로 취소 및 변경이 가능합니다")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.top, 16)
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    let isSubscribed: Bool
    let isPending: Bool
    let onPurchase: () -> Void

    private var productType: SubscriptionProduct? {
        SubscriptionProduct.allCases.first { $0.rawValue == product.id }
    }

    private var isPopular: Bool {
        product.id == SubscriptionProduct.yearly.rawValue
    }

    private var isRecommended: Bool {
        product.id == SubscriptionProduct.lifetime.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 배지 (인기/추천)
            if isPopular || isRecommended {
                HStack {
                    Spacer()
                    Text(isRecommended ? "추천" : "인기")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            isRecommended ?
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [.orange, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
            }

            HStack(spacing: 16) {
                // 아이콘
                if let productType = productType {
                    Image(systemName: productType.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)

                    if let productType = productType {
                        Text(productType.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title2)
                        .fontWeight(.bold)

                    if let subscription = product.subscription {
                        Text("/ \(subscription.subscriptionPeriod.unit.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("1회 결제")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 구독 버튼
                if isSubscribed {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("구독 중")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(10)
                } else if isPending {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("구독 예정")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(10)
                } else {
                    Button(action: onPurchase) {
                        Text("구독하기")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isRecommended ?
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    (isPopular ?
                     LinearGradient(
                        colors: [.orange, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                     ) :
                     LinearGradient(
                        colors: [.clear, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                     )),
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Subscription Period Extension
extension Product.SubscriptionPeriod.Unit {
    var localizedDescription: String {
        switch self {
        case .day:
            return "일"
        case .week:
            return "주"
        case .month:
            return "월"
        case .year:
            return "년"
        @unknown default:
            return ""
        }
    }
}

#Preview {
    SubscriptionView()
}

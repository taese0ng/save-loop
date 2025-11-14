import Foundation
import SwiftUI
import SwiftData

/// 프리미엄 기능 관리
class PremiumFeatureManager {
    static let shared = PremiumFeatureManager()

    private init() {}

    // MARK: - 무료 사용자 제한

    /// 무료 사용자 최대 봉투 개수
    let maxEnvelopesForFree = 2

    /// 무료 사용자 최대 저장 가능한 월 수
    let maxMonthsForFree = 3

    /// 무료 사용자 최대 거래 내역 개수 (봉투당)
    let maxTransactionsPerEnvelopeForFree = 30

    // MARK: - 기능 체크

    /// 봉투를 더 생성할 수 있는지 확인
    func canCreateMoreEnvelopes(currentCount: Int, isSubscribed: Bool) -> Bool {
        if isSubscribed {
            return true
        }
        return currentCount < maxEnvelopesForFree
    }

    /// 월별 데이터를 더 저장할 수 있는지 확인
    func canStoreMoreMonths(currentMonthCount: Int, isSubscribed: Bool) -> Bool {
        if isSubscribed {
            return true
        }
        return currentMonthCount < maxMonthsForFree
    }

    /// 거래 내역을 더 추가할 수 있는지 확인
    func canAddMoreTransactions(currentCount: Int, isSubscribed: Bool) -> Bool {
        if isSubscribed {
            return true
        }
        return currentCount < maxTransactionsPerEnvelopeForFree
    }

    // MARK: - 프리미엄 전용 기능

    /// iCloud 동기화 사용 가능 여부
    func canUseCloudSync(isSubscribed: Bool) -> Bool {
        return isSubscribed
    }

    // MARK: - 제한 메시지

    /// 봉투 생성 제한 메시지
    func getEnvelopeLimitMessage() -> String {
        return "무료 버전에서는 최대 \(maxEnvelopesForFree)개의 봉투만 만들 수 있습니다.\n프리미엄 멤버십으로 무제한 봉투를 만들어보세요!"
    }

    /// 월별 데이터 제한 메시지
    func getMonthLimitMessage() -> String {
        return "무료 버전에서는 최근 \(maxMonthsForFree)개월 데이터만 저장됩니다.\n프리미엄으로 무제한 데이터를 보관하세요!"
    }

    /// 거래 내역 제한 메시지
    func getTransactionLimitMessage() -> String {
        return "무료 버전에서는 봉투당 최대 \(maxTransactionsPerEnvelopeForFree)개의 거래 내역만 저장됩니다.\n프리미엄으로 무제한 기록을 남기세요!"
    }

    /// 프리미엄 전용 기능 메시지
    func getPremiumOnlyMessage(feature: String) -> String {
        return "\(feature)은(는) 프리미엄 전용 기능입니다.\n지금 업그레이드하고 더 많은 기능을 사용해보세요!"
    }
    
    // MARK: - 구독 해지 처리
    
    /// 구독 해지 시 지속형 봉투 만료 처리
    @MainActor
    func expirePersistentEnvelopesOnUnsubscribe(context: ModelContext) {
        let descriptor = FetchDescriptor<Envelope>(
            predicate: #Predicate<Envelope> { $0.envelopeType == "persistent" }
        )
        
        do {
            let persistentEnvelopes = try context.fetch(descriptor)
            let now = Date()
            
            var expiredCount = 0
            for envelope in persistentEnvelopes {
                // 이미 만료된 봉투는 skip
                if envelope.expirationDate != nil {
                    continue
                }
                
                envelope.expirationDate = now
                expiredCount += 1
            }
            
            if expiredCount > 0 {
                try context.save()
                print("✅ 지속형 봉투 \(expiredCount)개 만료 처리 완료")
            }
        } catch {
            print("❌ 지속형 봉투 만료 처리 실패: \(error)")
        }
    }
    
    /// 구독 재개 시 지속형 봉투 활성화
    @MainActor
    func reactivatePersistentEnvelopesOnSubscribe(context: ModelContext) {
        let descriptor = FetchDescriptor<Envelope>(
            predicate: #Predicate<Envelope> { $0.envelopeType == "persistent" }
        )
        
        do {
            let persistentEnvelopes = try context.fetch(descriptor)
            
            var reactivatedCount = 0
            for envelope in persistentEnvelopes {
                if envelope.expirationDate != nil {
                    envelope.expirationDate = nil
                    reactivatedCount += 1
                }
            }
            
            if reactivatedCount > 0 {
                try context.save()
                print("✅ 지속형 봉투 \(reactivatedCount)개 재활성화 완료")
            }
        } catch {
            print("❌ 지속형 봉투 재활성화 실패: \(error)")
        }
    }
    
    /// 현재 갱신 주기의 봉투 개수 계산 (UI 로직 중복 제거용)
    @MainActor
    func getCurrentCycleEnvelopeCount(
        allEnvelopes: [Envelope],
        currentCycle: (year: Int, month: Int),
        renewalDayManager: RenewalDayManager
    ) -> Int {
        return allEnvelopes.filter { envelope in
            // 만료된 봉투는 제외
            if envelope.isExpired {
                return false
            }
            
            if envelope.type == .persistent {
                // 지속형 봉투는 생성 갱신 주기 기준
                let envelopeCycle = renewalDayManager.getRenewalCycle(for: envelope.createdAt)
                return envelopeCycle.year == currentCycle.year && envelopeCycle.month == currentCycle.month
            } else {
                // 일반/반복 봉투는 현재 갱신 주기 기준
                let envelopeCycle = renewalDayManager.getRenewalCycle(for: envelope.createdAt)
                return envelopeCycle.year == currentCycle.year && envelopeCycle.month == currentCycle.month
            }
        }.count
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// 프리미엄 기능 잠금 오버레이
    @ViewBuilder
    func premiumLock(
        isLocked: Bool,
        showingSubscription: Binding<Bool>
    ) -> some View {
        self.overlay {
            if isLocked {
                ZStack {
                    Color.black.opacity(0.3)

                    VStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)

                        Text("premium.lock.title".localized) // 프리미엄 전용
                            .font(.headline)
                            .foregroundColor(.white)

                        Button(action: {
                            showingSubscription.wrappedValue = true
                        }) {
                            Text("subscription.upgrade".localized) // 업그레이드
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }
}

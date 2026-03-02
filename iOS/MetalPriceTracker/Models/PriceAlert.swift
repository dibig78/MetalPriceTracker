import Foundation

// MARK: - 가격 알림 모델 (Supabase price_alerts 테이블)
struct PriceAlert: Codable, Identifiable {
    let id: Int?
    let deviceToken: String
    let metalId: Int
    let targetPrice: Double
    let direction: AlertDirection
    let isActive: Bool
    let triggeredAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case deviceToken = "device_token"
        case metalId = "metal_id"
        case targetPrice = "target_price"
        case direction
        case isActive = "is_active"
        case triggeredAt = "triggered_at"
    }

    // 알림 방향
    enum AlertDirection: String, Codable, CaseIterable {
        case above = "above"  // 이상
        case below = "below"  // 이하

        var displayText: String {
            switch self {
            case .above: return "이상 도달 시"
            case .below: return "이하 도달 시"
            }
        }
    }

    // 포맷된 목표가
    var formattedTargetPrice: String {
        String(format: "$%.2f", targetPrice)
    }
}

// MARK: - 알림 생성용 모델
struct CreateAlertRequest: Codable {
    let deviceToken: String
    let metalId: Int
    let targetPrice: Double
    let direction: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case deviceToken = "device_token"
        case metalId = "metal_id"
        case targetPrice = "target_price"
        case direction
        case isActive = "is_active"
    }
}

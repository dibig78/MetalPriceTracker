import SwiftUI

// MARK: - 색상 확장
extension Color {
    // 금속별 테마 색상
    static func metalColor(for symbol: String) -> Color {
        switch symbol {
        case "CU": return .orange       // 구리
        case "AL": return .gray         // 알루미늄
        case "ZN": return .blue         // 아연
        case "NI": return .green        // 니켈
        case "PB": return .purple       // 납
        case "SN": return .brown        // 주석
        case "AG": return .mint         // 은
        default: return .primary
        }
    }

    // 등락 색상
    static let priceUp = Color.red       // 상승 (한국식)
    static let priceDown = Color.blue    // 하락 (한국식)
    static let priceFlat = Color.gray    // 보합

    static func priceChangeColor(for value: Double?) -> Color {
        guard let value = value else { return .priceFlat }
        if value > 0 { return .priceUp }
        if value < 0 { return .priceDown }
        return .priceFlat
    }

    // 앱 테마 색상
    static let appBackground = Color(.systemGroupedBackground)
    static let cardBackground = Color(.systemBackground)
}

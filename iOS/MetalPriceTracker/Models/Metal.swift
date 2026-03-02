import Foundation

// MARK: - 금속 모델 (Supabase metals 테이블)
struct Metal: Codable, Identifiable, Hashable {
    let id: Int
    let symbol: String
    let nameEn: String
    let nameKo: String
    let unit: String
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, symbol, unit
        case nameEn = "name_en"
        case nameKo = "name_ko"
        case isActive = "is_active"
    }

    // 금속 아이콘 색상 (UI용)
    var displayColor: String {
        switch symbol {
        case "CU": return "orange"      // 구리
        case "AL": return "gray"        // 알루미늄
        case "ZN": return "blue"        // 아연
        case "NI": return "green"       // 니켈
        case "PB": return "purple"      // 납
        case "SN": return "brown"       // 주석
        default: return "primary"
        }
    }
}

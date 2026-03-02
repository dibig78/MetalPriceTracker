import Foundation

// MARK: - 일별 시세 모델 (Supabase daily_prices 테이블)
struct DailyPrice: Codable, Identifiable {
    let id: Int
    let metalId: Int
    let priceDate: String
    let openPrice: Double?
    let highPrice: Double?
    let lowPrice: Double?
    let closePrice: Double?
    let changeAmount: Double?
    let changePercent: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case metalId = "metal_id"
        case priceDate = "price_date"
        case openPrice = "open_price"
        case highPrice = "high_price"
        case lowPrice = "low_price"
        case closePrice = "close_price"
        case changeAmount = "change_amount"
        case changePercent = "change_percent"
    }

    // 날짜 변환 (String -> Date)
    var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: priceDate)
    }

    // 등락 방향
    var isPositive: Bool {
        (changeAmount ?? 0) >= 0
    }

    // 포맷된 가격 문자열
    var formattedPrice: String {
        guard let price = closePrice else { return "-" }
        return String(format: "$%.2f", price)
    }

    // 포맷된 변동률 문자열
    var formattedChangePercent: String {
        guard let percent = changePercent else { return "-" }
        let sign = percent >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, percent)
    }

    // 포맷된 변동액 문자열
    var formattedChangeAmount: String {
        guard let amount = changeAmount else { return "-" }
        let sign = amount >= 0 ? "+" : ""
        return String(format: "%@$%.2f", sign, amount)
    }
}

// MARK: - 최신 시세 뷰 모델 (latest_prices 뷰)
struct LatestPrice: Codable, Identifiable {
    let metalId: Int
    let symbol: String
    let nameEn: String
    let nameKo: String
    let unit: String
    let priceDate: String?
    let closePrice: Double?
    let openPrice: Double?
    let highPrice: Double?
    let lowPrice: Double?
    let changeAmount: Double?
    let changePercent: Double?

    var id: Int { metalId }

    enum CodingKeys: String, CodingKey {
        case metalId = "metal_id"
        case symbol
        case nameEn = "name_en"
        case nameKo = "name_ko"
        case unit
        case priceDate = "price_date"
        case closePrice = "close_price"
        case openPrice = "open_price"
        case highPrice = "high_price"
        case lowPrice = "low_price"
        case changeAmount = "change_amount"
        case changePercent = "change_percent"
    }

    var isPositive: Bool {
        (changeAmount ?? 0) >= 0
    }

    var formattedPrice: String {
        guard let price = closePrice else { return "-" }
        return String(format: "$%.2f", price)
    }

    var formattedChangePercent: String {
        guard let percent = changePercent else { return "-" }
        let sign = percent >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, percent)
    }

    var displayColor: String {
        switch symbol {
        case "CU": return "orange"      // 구리
        case "AL": return "gray"        // 알루미늄
        case "ZN": return "blue"        // 아연
        case "NI": return "green"       // 니켈
        case "PB": return "purple"      // 납
        case "SN": return "brown"       // 주석
        case "AG": return "mint"        // 은
        default: return "primary"
        }
    }
}

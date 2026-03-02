import Foundation
import Supabase

// MARK: - Supabase 서비스 (데이터 통신 담당)
@MainActor
final class SupabaseService {

    static let shared = SupabaseService()

    private let client = SupabaseClient(
        supabaseURL: URL(string: "https://qqlohybmnlpuwvuwsxkp.supabase.co")!,
        supabaseKey: "sb_publishable_IqriRb5tGd2a0Ae_DoiKeg_kEZ--f0D"
    )

    private init() {}

    // MARK: - 금속 목록 조회

    func fetchMetals() async throws -> [Metal] {
        let response: [Metal] = try await client
            .from("metals")
            .select()
            .eq("is_active", value: true)
            .order("id")
            .execute()
            .value
        return response
    }

    // MARK: - 최신 시세 조회 (latest_prices 뷰)

    func fetchLatestPrices() async throws -> [LatestPrice] {
        let response: [LatestPrice] = try await client
            .from("latest_prices")
            .select()
            .execute()
            .value
        return response
    }

    // MARK: - 기간별 시세 조회

    func fetchPrices(metalId: Int, from startDate: Date?, to endDate: Date = Date()) async throws -> [DailyPrice] {
        var query = client
            .from("daily_prices")
            .select()
            .eq("metal_id", value: metalId)
            .order("price_date", ascending: true)

        if let startDate = startDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            query = query.gte("price_date", value: formatter.string(from: startDate))
            query = query.lte("price_date", value: formatter.string(from: endDate))
        }

        let response: [DailyPrice] = try await query.execute().value
        return response
    }

    // MARK: - 여러 금속의 기간별 시세 조회 (비교 분석용)

    func fetchPricesForMetals(metalIds: [Int], from startDate: Date?, to endDate: Date = Date()) async throws -> [Int: [DailyPrice]] {
        var result: [Int: [DailyPrice]] = [:]
        for metalId in metalIds {
            let prices = try await fetchPrices(metalId: metalId, from: startDate, to: endDate)
            result[metalId] = prices
        }
        return result
    }

    // MARK: - 통계 데이터 조회

    func fetchPriceStats(metalId: Int, from startDate: Date?, to endDate: Date = Date()) async throws -> PriceStats {
        let prices = try await fetchPrices(metalId: metalId, from: startDate, to: endDate)

        let closePrices = prices.compactMap { $0.closePrice }
        guard !closePrices.isEmpty else {
            return PriceStats(high: 0, low: 0, average: 0, count: 0)
        }

        let high = closePrices.max() ?? 0
        let low = closePrices.min() ?? 0
        let average = closePrices.reduce(0, +) / Double(closePrices.count)

        return PriceStats(high: high, low: low, average: average, count: closePrices.count)
    }

    // MARK: - 알림 관련

    func fetchAlerts(deviceToken: String) async throws -> [PriceAlert] {
        let response: [PriceAlert] = try await client
            .from("price_alerts")
            .select()
            .eq("device_token", value: deviceToken)
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func createAlert(_ alert: CreateAlertRequest) async throws {
        try await client
            .from("price_alerts")
            .insert(alert)
            .execute()
    }

    func updateAlertStatus(alertId: Int, isActive: Bool) async throws {
        try await client
            .from("price_alerts")
            .update(["is_active": isActive])
            .eq("id", value: alertId)
            .execute()
    }

    func deleteAlert(alertId: Int) async throws {
        try await client
            .from("price_alerts")
            .delete()
            .eq("id", value: alertId)
            .execute()
    }
}

// MARK: - 통계 모델
struct PriceStats {
    let high: Double
    let low: Double
    let average: Double
    let count: Int

    var formattedHigh: String { String(format: "$%.2f", high) }
    var formattedLow: String { String(format: "$%.2f", low) }
    var formattedAverage: String { String(format: "$%.2f", average) }
}

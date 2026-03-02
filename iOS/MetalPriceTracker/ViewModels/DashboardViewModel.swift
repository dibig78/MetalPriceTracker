import Foundation

// MARK: - 대시보드 뷰모델
@MainActor
final class DashboardViewModel: ObservableObject {

    @Published var latestPrices: [LatestPrice] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = SupabaseService.shared

    // MARK: - 최신 시세 로드

    func loadLatestPrices() async {
        isLoading = true
        errorMessage = nil

        do {
            latestPrices = try await service.fetchLatestPrices()
        } catch {
            errorMessage = "시세 데이터를 불러오는데 실패했습니다.\n\(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - 가장 많이 오른 금속

    var topGainer: LatestPrice? {
        latestPrices
            .filter { ($0.changePercent ?? 0) > 0 }
            .max { ($0.changePercent ?? 0) < ($1.changePercent ?? 0) }
    }

    // MARK: - 가장 많이 내린 금속

    var topLoser: LatestPrice? {
        latestPrices
            .filter { ($0.changePercent ?? 0) < 0 }
            .min { ($0.changePercent ?? 0) < ($1.changePercent ?? 0) }
    }

    // MARK: - 최신 날짜

    var latestDate: String {
        latestPrices.first?.priceDate ?? "-"
    }
}

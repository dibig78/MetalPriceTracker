import Foundation

// MARK: - 차트 뷰모델
@MainActor
final class ChartViewModel: ObservableObject {

    @Published var prices: [DailyPrice] = []
    @Published var stats: PriceStats?
    @Published var selectedRange: DateRangeOption = .threeMonths
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var chartType: ChartType = .line

    // 커스텀 날짜 범위
    @Published var customStartDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @Published var customEndDate = Date()

    let metalId: Int
    private let service = SupabaseService.shared

    init(metalId: Int) {
        self.metalId = metalId
    }

    // MARK: - 차트 타입
    enum ChartType: String, CaseIterable {
        case line = "라인"
        case candle = "캔들"
    }

    // MARK: - 데이터 로드

    func loadPrices() async {
        isLoading = true
        errorMessage = nil

        let startDate: Date?
        let endDate = Date()

        if selectedRange == .custom {
            startDate = customStartDate
        } else {
            startDate = selectedRange.startDate()
        }

        do {
            prices = try await service.fetchPrices(metalId: metalId, from: startDate, to: endDate)
            stats = try await service.fetchPriceStats(metalId: metalId, from: startDate, to: endDate)
        } catch {
            errorMessage = "차트 데이터를 불러오는데 실패했습니다."
        }

        isLoading = false
    }

    // MARK: - 기간 변경 시 데이터 다시 로드

    func onRangeChanged() async {
        await loadPrices()
    }

    // MARK: - 차트 데이터 포인트 (Date, Double) 변환

    var chartDataPoints: [(date: Date, price: Double)] {
        prices.compactMap { dailyPrice in
            guard let date = dailyPrice.date,
                  let price = dailyPrice.closePrice else { return nil }
            return (date: date, price: price)
        }
    }

    // MARK: - 캔들 차트 데이터

    var candleDataPoints: [(date: Date, open: Double, high: Double, low: Double, close: Double)] {
        prices.compactMap { dailyPrice in
            guard let date = dailyPrice.date,
                  let open = dailyPrice.openPrice ?? dailyPrice.closePrice,
                  let close = dailyPrice.closePrice else { return nil }
            let high = dailyPrice.highPrice ?? max(open, close)
            let low = dailyPrice.lowPrice ?? min(open, close)
            return (date: date, open: open, high: high, low: low, close: close)
        }
    }

    // MARK: - 가격 범위 (Y축)

    var priceRange: ClosedRange<Double> {
        let closePrices = prices.compactMap { $0.closePrice }
        guard let min = closePrices.min(), let max = closePrices.max() else {
            return 0...100
        }
        let padding = (max - min) * 0.1
        return (min - padding)...(max + padding)
    }
}

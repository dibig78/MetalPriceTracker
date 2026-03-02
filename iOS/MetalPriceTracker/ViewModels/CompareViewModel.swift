import Foundation

// MARK: - 비교 분석 뷰모델
@MainActor
final class CompareViewModel: ObservableObject {

    @Published var metals: [Metal] = []
    @Published var selectedMetalIds: Set<Int> = []
    @Published var pricesMap: [Int: [DailyPrice]] = [:]
    @Published var selectedRange: DateRangeOption = .threeMonths
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var compareMode: CompareMode = .price

    private let service = SupabaseService.shared

    // 비교 모드
    enum CompareMode: String, CaseIterable {
        case price = "가격"
        case percentChange = "등락률(%)"
    }

    // MARK: - 초기 데이터 로드

    func loadMetals() async {
        do {
            metals = try await service.fetchMetals()
            // 기본 선택: 구리, 알루미늄
            if selectedMetalIds.isEmpty, metals.count >= 2 {
                selectedMetalIds = Set(metals.prefix(2).map { $0.id })
            }
            await loadComparisonData()
        } catch {
            errorMessage = "금속 목록을 불러오는데 실패했습니다."
        }
    }

    // MARK: - 비교 데이터 로드

    func loadComparisonData() async {
        guard !selectedMetalIds.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        let startDate = selectedRange.startDate()

        do {
            pricesMap = try await service.fetchPricesForMetals(
                metalIds: Array(selectedMetalIds),
                from: startDate
            )
        } catch {
            errorMessage = "비교 데이터를 불러오는데 실패했습니다."
        }

        isLoading = false
    }

    // MARK: - 금속 선택 토글

    func toggleMetal(_ metalId: Int) {
        if selectedMetalIds.contains(metalId) {
            selectedMetalIds.remove(metalId)
        } else {
            if selectedMetalIds.count < 3 {
                selectedMetalIds.insert(metalId)
            }
        }
    }

    // MARK: - 차트 데이터: 가격 비교

    func priceDataPoints(for metalId: Int) -> [(date: Date, price: Double)] {
        (pricesMap[metalId] ?? []).compactMap { dailyPrice in
            guard let date = dailyPrice.date,
                  let price = dailyPrice.closePrice else { return nil }
            return (date: date, price: price)
        }
    }

    // MARK: - 차트 데이터: 등락률 비교 (기준일 대비 %)

    func percentChangeDataPoints(for metalId: Int) -> [(date: Date, percent: Double)] {
        let prices = pricesMap[metalId] ?? []
        guard let basePrice = prices.first?.closePrice, basePrice > 0 else { return [] }

        return prices.compactMap { dailyPrice in
            guard let date = dailyPrice.date,
                  let price = dailyPrice.closePrice else { return nil }
            let percent = ((price - basePrice) / basePrice) * 100
            return (date: date, percent: percent)
        }
    }

    // MARK: - 금속 이름 조회

    func metalName(for id: Int) -> String {
        metals.first { $0.id == id }?.nameKo ?? ""
    }

    func metalSymbol(for id: Int) -> String {
        metals.first { $0.id == id }?.symbol ?? ""
    }
}

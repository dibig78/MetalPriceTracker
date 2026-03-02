import Foundation

// MARK: - 기간 선택 모델
enum DateRangeOption: String, CaseIterable, Identifiable {
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case all = "전체"
    case custom = "직접선택"

    var id: String { rawValue }

    var displayText: String { rawValue }

    // 시작 날짜 계산
    func startDate(from endDate: Date = Date()) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .oneWeek:
            return calendar.date(byAdding: .day, value: -7, to: endDate)
        case .oneMonth:
            return calendar.date(byAdding: .month, value: -1, to: endDate)
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: endDate)
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: endDate)
        case .oneYear:
            return calendar.date(byAdding: .year, value: -1, to: endDate)
        case .all:
            return nil  // 전체 기간
        case .custom:
            return nil  // 사용자 직접 선택
        }
    }
}

import Foundation

// MARK: - 날짜 포맷 확장
extension DateFormatter {
    // API용 날짜 포맷 (yyyy-MM-dd)
    static let apiDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // 화면 표시용 (MM/dd)
    static let shortDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()

    // 화면 표시용 (yyyy년 MM월 dd일)
    static let koreanDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    // 차트 축 표시용 (M/d)
    static let chartAxis: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()

    // 차트 축 표시용 - 월 (yyyy.MM)
    static let chartAxisMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM"
        return formatter
    }()
}

// MARK: - Date 확장
extension Date {
    var apiDateString: String {
        DateFormatter.apiDate.string(from: self)
    }

    var shortDisplayString: String {
        DateFormatter.shortDisplay.string(from: self)
    }

    var koreanDisplayString: String {
        DateFormatter.koreanDisplay.string(from: self)
    }
}

// MARK: - String -> Date 변환
extension String {
    var toApiDate: Date? {
        DateFormatter.apiDate.date(from: self)
    }
}

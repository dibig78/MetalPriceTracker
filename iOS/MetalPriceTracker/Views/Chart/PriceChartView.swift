import SwiftUI
import Charts

// MARK: - 가격 차트 상세 화면
struct PriceChartView: View {

    let metalId: Int
    let metalName: String
    let symbol: String

    @StateObject private var viewModel: ChartViewModel
    @State private var showDatePicker = false

    init(metalId: Int, metalName: String, symbol: String) {
        self.metalId = metalId
        self.metalName = metalName
        self.symbol = symbol
        self._viewModel = StateObject(wrappedValue: ChartViewModel(metalId: metalId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 차트 타입 선택
                chartTypeSelector

                // 기간 선택
                dateRangeSelector

                // 커스텀 날짜 선택기
                if viewModel.selectedRange == .custom {
                    customDatePicker
                }

                // 차트 영역
                chartSection

                // 통계 정보
                if let stats = viewModel.stats {
                    statsSection(stats)
                }
            }
            .padding()
        }
        .background(Color.appBackground)
        .navigationTitle(metalName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadPrices()
        }
    }

    // MARK: - 차트 타입 선택 (라인/캔들)

    private var chartTypeSelector: some View {
        Picker("차트 타입", selection: $viewModel.chartType) {
            ForEach(ChartViewModel.ChartType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - 기간 선택 버튼

    private var dateRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DateRangeOption.allCases) { option in
                    Button {
                        viewModel.selectedRange = option
                        Task { await viewModel.onRangeChanged() }
                    } label: {
                        Text(option.displayText)
                            .font(.caption)
                            .fontWeight(viewModel.selectedRange == option ? .bold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedRange == option
                                    ? Color.metalColor(for: symbol)
                                    : Color(.systemGray5)
                            )
                            .foregroundStyle(
                                viewModel.selectedRange == option ? .white : .primary
                            )
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - 커스텀 날짜 선택기

    private var customDatePicker: some View {
        VStack(spacing: 12) {
            DatePicker("시작일", selection: $viewModel.customStartDate, displayedComponents: .date)
            DatePicker("종료일", selection: $viewModel.customEndDate, displayedComponents: .date)
            Button("조회") {
                Task { await viewModel.onRangeChanged() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.metalColor(for: symbol))
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 차트 영역

    private var chartSection: some View {
        VStack(alignment: .leading) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            } else if viewModel.prices.isEmpty {
                Text("데이터가 없습니다")
                    .foregroundStyle(.secondary)
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            } else {
                switch viewModel.chartType {
                case .line:
                    lineChart
                case .candle:
                    candleChart
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 라인 차트

    private var lineChart: some View {
        Chart {
            ForEach(viewModel.chartDataPoints, id: \.date) { point in
                LineMark(
                    x: .value("날짜", point.date),
                    y: .value("가격", point.price)
                )
                .foregroundStyle(Color.metalColor(for: symbol))

                AreaMark(
                    x: .value("날짜", point.date),
                    y: .value("가격", point.price)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.metalColor(for: symbol).opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartYScale(domain: viewModel.priceRange)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text(String(format: "$%.0f", price))
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 300)
    }

    // MARK: - 캔들 차트 (간소화 버전 - Swift Charts 활용)

    private var candleChart: some View {
        Chart {
            ForEach(viewModel.candleDataPoints, id: \.date) { point in
                // 심지 (High-Low 범위)
                RectangleMark(
                    x: .value("날짜", point.date),
                    yStart: .value("Low", point.low),
                    yEnd: .value("High", point.high),
                    width: 2
                )
                .foregroundStyle(point.close >= point.open ? Color.priceUp : Color.priceDown)

                // 몸통 (Open-Close 범위)
                RectangleMark(
                    x: .value("날짜", point.date),
                    yStart: .value("Open", point.open),
                    yEnd: .value("Close", point.close),
                    width: 8
                )
                .foregroundStyle(point.close >= point.open ? Color.priceUp : Color.priceDown)
            }
        }
        .chartYScale(domain: viewModel.priceRange)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let price = value.as(Double.self) {
                        Text(String(format: "$%.0f", price))
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 300)
    }

    // MARK: - 통계 섹션

    private func statsSection(_ stats: PriceStats) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("기간 통계")
                .font(.headline)

            HStack(spacing: 0) {
                statItem(title: "최고가", value: stats.formattedHigh, color: .priceUp)
                Divider()
                statItem(title: "최저가", value: stats.formattedLow, color: .priceDown)
                Divider()
                statItem(title: "평균가", value: stats.formattedAverage, color: .primary)
            }
            .frame(height: 60)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statItem(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        PriceChartView(metalId: 1, metalName: "구리", symbol: "CU")
    }
}

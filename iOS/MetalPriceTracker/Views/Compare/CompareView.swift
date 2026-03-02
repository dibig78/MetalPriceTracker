import SwiftUI
import Charts

// MARK: - 비교 분석 화면
struct CompareView: View {

    @StateObject private var viewModel = CompareViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 금속 선택 (최대 3개)
                    metalSelector

                    // 비교 모드 선택
                    compareModeSelector

                    // 기간 선택
                    dateRangeSelector

                    // 비교 차트
                    chartSection
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("비교 분석")
            .task {
                await viewModel.loadMetals()
            }
        }
    }

    // MARK: - 금속 선택 (칩 형태)

    private var metalSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("금속 선택 (최대 3개)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 8) {
                ForEach(viewModel.metals) { metal in
                    Button {
                        viewModel.toggleMetal(metal.id)
                        Task { await viewModel.loadComparisonData() }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.metalColor(for: metal.symbol))
                                .frame(width: 12, height: 12)
                            Text(metal.nameKo)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            viewModel.selectedMetalIds.contains(metal.id)
                                ? Color.metalColor(for: metal.symbol).opacity(0.2)
                                : Color(.systemGray5)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(
                                    viewModel.selectedMetalIds.contains(metal.id)
                                        ? Color.metalColor(for: metal.symbol)
                                        : Color.clear,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 비교 모드 선택

    private var compareModeSelector: some View {
        Picker("비교 모드", selection: $viewModel.compareMode) {
            ForEach(CompareViewModel.CompareMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - 기간 선택

    private var dateRangeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DateRangeOption.allCases.filter { $0 != .custom }) { option in
                    Button {
                        viewModel.selectedRange = option
                        Task { await viewModel.loadComparisonData() }
                    } label: {
                        Text(option.displayText)
                            .font(.caption)
                            .fontWeight(viewModel.selectedRange == option ? .bold : .regular)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedRange == option
                                    ? Color.accentColor
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

    // MARK: - 차트 영역

    private var chartSection: some View {
        VStack(alignment: .leading) {
            if viewModel.isLoading {
                ProgressView()
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            } else if viewModel.selectedMetalIds.isEmpty {
                Text("비교할 금속을 선택해주세요")
                    .foregroundStyle(.secondary)
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            } else {
                switch viewModel.compareMode {
                case .price:
                    priceCompareChart
                case .percentChange:
                    percentCompareChart
                }

                // 범례
                legendView
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 가격 비교 차트

    private var priceCompareChart: some View {
        Chart {
            ForEach(Array(viewModel.selectedMetalIds), id: \.self) { metalId in
                let points = viewModel.priceDataPoints(for: metalId)
                let symbol = viewModel.metalSymbol(for: metalId)

                ForEach(points, id: \.date) { point in
                    LineMark(
                        x: .value("날짜", point.date),
                        y: .value("가격", point.price),
                        series: .value("금속", symbol)
                    )
                    .foregroundStyle(Color.metalColor(for: symbol))
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
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

    // MARK: - 등락률 비교 차트

    private var percentCompareChart: some View {
        Chart {
            ForEach(Array(viewModel.selectedMetalIds), id: \.self) { metalId in
                let points = viewModel.percentChangeDataPoints(for: metalId)
                let symbol = viewModel.metalSymbol(for: metalId)

                ForEach(points, id: \.date) { point in
                    LineMark(
                        x: .value("날짜", point.date),
                        y: .value("변동률", point.percent),
                        series: .value("금속", symbol)
                    )
                    .foregroundStyle(Color.metalColor(for: symbol))
                }
            }

            // 기준선 (0%)
            RuleMark(y: .value("기준", 0))
                .foregroundStyle(.gray.opacity(0.5))
                .lineStyle(StrokeStyle(dash: [5, 5]))
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let percent = value.as(Double.self) {
                        Text(String(format: "%.1f%%", percent))
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 300)
    }

    // MARK: - 범례

    private var legendView: some View {
        HStack(spacing: 16) {
            ForEach(Array(viewModel.selectedMetalIds), id: \.self) { metalId in
                let symbol = viewModel.metalSymbol(for: metalId)
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.metalColor(for: symbol))
                        .frame(width: 8, height: 8)
                    Text(viewModel.metalName(for: metalId))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - FlowLayout (가로 줄바꿈 레이아웃)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    CompareView()
}

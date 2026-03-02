import SwiftUI

// MARK: - 대시보드 메인 화면
struct DashboardView: View {

    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 최신 업데이트 날짜
                    if !viewModel.latestPrices.isEmpty {
                        HStack {
                            Text("최종 업데이트")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(viewModel.latestDate)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    // 에러 메시지
                    if let error = viewModel.errorMessage {
                        ErrorBannerView(message: error)
                            .padding(.horizontal)
                    }

                    // 금속별 시세 카드
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.latestPrices) { price in
                            NavigationLink(value: price) {
                                MetalCardView(price: price)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("LME 시세")
            .navigationDestination(for: LatestPrice.self) { price in
                PriceChartView(metalId: price.metalId, metalName: price.nameKo, symbol: price.symbol)
            }
            .refreshable {
                await viewModel.loadLatestPrices()
            }
            .task {
                await viewModel.loadLatestPrices()
            }
            .overlay {
                if viewModel.isLoading && viewModel.latestPrices.isEmpty {
                    ProgressView("시세 불러오는 중...")
                }
            }
        }
    }
}

// MARK: - 에러 배너
struct ErrorBannerView: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    DashboardView()
}

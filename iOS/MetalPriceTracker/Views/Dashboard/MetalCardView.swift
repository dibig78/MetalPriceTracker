import SwiftUI

// MARK: - 금속별 시세 카드
struct MetalCardView: View {

    let price: LatestPrice

    var body: some View {
        HStack(spacing: 16) {
            // 금속 아이콘
            Circle()
                .fill(Color.metalColor(for: price.symbol))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(price.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }

            // 금속명 + 심볼
            VStack(alignment: .leading, spacing: 4) {
                Text(price.nameKo)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(price.nameEn)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 가격 + 변동률
            VStack(alignment: .trailing, spacing: 4) {
                Text(price.formattedPrice)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)

                HStack(spacing: 4) {
                    Image(systemName: changeIcon)
                        .font(.caption2)
                    Text(formattedChange)
                        .font(.system(.caption, design: .monospaced))
                }
                .foregroundStyle(changeColor)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // 변동 아이콘
    private var changeIcon: String {
        guard let change = price.changeAmount else { return "minus" }
        if change > 0 { return "arrow.up.right" }
        if change < 0 { return "arrow.down.right" }
        return "minus"
    }

    // 변동률 텍스트
    private var formattedChange: String {
        guard let percent = price.changePercent else { return "-" }
        let sign = percent >= 0 ? "+" : ""
        return String(format: "%@%.2f%%", sign, percent)
    }

    // 변동 색상
    private var changeColor: Color {
        Color.priceChangeColor(for: price.changeAmount)
    }
}

#Preview {
    MetalCardView(price: LatestPrice(
        metalId: 1,
        symbol: "CU",
        nameEn: "Copper",
        nameKo: "구리",
        unit: "USD/MT",
        priceDate: "2024-01-15",
        closePrice: 8543.50,
        openPrice: 8500.00,
        highPrice: 8560.00,
        lowPrice: 8490.00,
        changeAmount: 43.50,
        changePercent: 0.51
    ))
    .padding()
}

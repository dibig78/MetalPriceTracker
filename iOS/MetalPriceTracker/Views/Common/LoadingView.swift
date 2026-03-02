import SwiftUI

// MARK: - 로딩 뷰
struct LoadingView: View {
    var message: String = "불러오는 중..."

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 빈 상태 뷰
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Loading") {
    LoadingView()
}

#Preview("Empty") {
    EmptyStateView(
        icon: "chart.bar.xaxis",
        title: "데이터 없음",
        message: "아직 수집된 시세 데이터가 없습니다.\n잠시 후 다시 시도해주세요."
    )
}

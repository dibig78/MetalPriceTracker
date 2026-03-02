import SwiftUI

// MARK: - 메인 탭 네비게이션
struct ContentView: View {

    @State private var selectedTab: Tab = .dashboard

    enum Tab: String {
        case dashboard = "대시보드"
        case compare = "비교"
        case alerts = "알림"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 탭 1: 대시보드 (메인)
            DashboardView()
                .tabItem {
                    Label("시세", systemImage: "chart.bar.fill")
                }
                .tag(Tab.dashboard)

            // 탭 2: 비교 분석
            CompareView()
                .tabItem {
                    Label("비교", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.compare)

            // 탭 3: 알림 설정
            AlertSettingView()
                .tabItem {
                    Label("알림", systemImage: "bell.fill")
                }
                .tag(Tab.alerts)
        }
        .tint(.orange)
    }
}

#Preview {
    ContentView()
}

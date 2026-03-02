import SwiftUI

// MARK: - 알림 설정 화면
struct AlertSettingView: View {

    @StateObject private var viewModel = AlertViewModel()

    var body: some View {
        NavigationStack {
            List {
                // 새 알림 추가 섹션
                addAlertSection

                // 활성 알림 목록
                if !activeAlerts.isEmpty {
                    Section("활성 알림") {
                        ForEach(activeAlerts) { alert in
                            alertRow(alert)
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.deleteAlert(activeAlerts[index])
                                }
                            }
                        }
                    }
                }

                // 비활성/트리거된 알림 목록
                if !inactiveAlerts.isEmpty {
                    Section("완료된 알림") {
                        ForEach(inactiveAlerts) { alert in
                            alertRow(alert)
                        }
                        .onDelete { indexSet in
                            Task {
                                for index in indexSet {
                                    await viewModel.deleteAlert(inactiveAlerts[index])
                                }
                            }
                        }
                    }
                }

                // 에러 메시지
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("가격 알림")
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .overlay {
                if viewModel.isLoading && viewModel.alerts.isEmpty {
                    ProgressView("불러오는 중...")
                }
            }
        }
    }

    // MARK: - 활성/비활성 알림 분류

    private var activeAlerts: [PriceAlert] {
        viewModel.alerts.filter { $0.isActive }
    }

    private var inactiveAlerts: [PriceAlert] {
        viewModel.alerts.filter { !$0.isActive }
    }

    // MARK: - 새 알림 추가 섹션

    private var addAlertSection: some View {
        Section("새 알림 추가") {
            // 금속 선택
            Picker("금속", selection: $viewModel.selectedMetalId) {
                ForEach(viewModel.metals) { metal in
                    Text(metal.nameKo).tag(Optional(metal.id))
                }
            }

            // 목표가 입력
            HStack {
                Text("목표가")
                Spacer()
                TextField("예: 8500.00", text: $viewModel.targetPriceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 150)
                Text("USD/MT")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 방향 선택
            Picker("조건", selection: $viewModel.selectedDirection) {
                ForEach(PriceAlert.AlertDirection.allCases, id: \.self) { direction in
                    Text(direction.displayText).tag(direction)
                }
            }
            .pickerStyle(.segmented)

            // 추가 버튼
            Button {
                Task {
                    let success = await viewModel.createAlert()
                    if success {
                        // 폼 초기화는 viewModel에서 처리
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("알림 추가")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.targetPriceText.isEmpty)
        }
    }

    // MARK: - 알림 행

    private func alertRow(_ alert: PriceAlert) -> some View {
        HStack {
            // 금속 아이콘
            Circle()
                .fill(Color.metalColor(for: viewModel.metalSymbol(for: alert.metalId)))
                .frame(width: 32, height: 32)
                .overlay {
                    Text(viewModel.metalSymbol(for: alert.metalId))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }

            // 알림 정보
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.metalName(for: alert.metalId))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(alert.formattedTargetPrice) \(alert.direction.displayText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 활성/비활성 토글
            Toggle("", isOn: Binding(
                get: { alert.isActive },
                set: { _ in
                    Task { await viewModel.toggleAlert(alert) }
                }
            ))
            .labelsHidden()
        }
    }
}

#Preview {
    AlertSettingView()
}

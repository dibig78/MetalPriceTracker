import Foundation

// MARK: - 알림 뷰모델
@MainActor
final class AlertViewModel: ObservableObject {

    @Published var alerts: [PriceAlert] = []
    @Published var metals: [Metal] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // 새 알림 생성 폼
    @Published var selectedMetalId: Int?
    @Published var targetPriceText: String = ""
    @Published var selectedDirection: PriceAlert.AlertDirection = .above
    @Published var showingAddAlert = false

    private let service = SupabaseService.shared
    private let notificationService = NotificationService.shared

    // MARK: - 데이터 로드

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            metals = try await service.fetchMetals()
            if selectedMetalId == nil, let first = metals.first {
                selectedMetalId = first.id
            }
            alerts = try await service.fetchAlerts(deviceToken: notificationService.deviceToken)
        } catch {
            errorMessage = "알림 데이터를 불러오는데 실패했습니다."
        }

        isLoading = false
    }

    // MARK: - 알림 생성

    func createAlert() async -> Bool {
        guard let metalId = selectedMetalId,
              let targetPrice = Double(targetPriceText),
              targetPrice > 0 else {
            errorMessage = "올바른 목표가를 입력해주세요."
            return false
        }

        // 알림 권한 요청
        let granted = await notificationService.requestPermission()
        if !granted {
            errorMessage = "알림 권한이 필요합니다. 설정에서 알림을 허용해주세요."
            return false
        }

        let request = CreateAlertRequest(
            deviceToken: notificationService.deviceToken,
            metalId: metalId,
            targetPrice: targetPrice,
            direction: selectedDirection.rawValue,
            isActive: true
        )

        do {
            try await service.createAlert(request)
            // 폼 초기화
            targetPriceText = ""
            // 목록 새로고침
            alerts = try await service.fetchAlerts(deviceToken: notificationService.deviceToken)
            return true
        } catch {
            errorMessage = "알림 생성에 실패했습니다."
            return false
        }
    }

    // MARK: - 알림 토글

    func toggleAlert(_ alert: PriceAlert) async {
        guard let id = alert.id else { return }

        do {
            try await service.updateAlertStatus(alertId: id, isActive: !alert.isActive)
            alerts = try await service.fetchAlerts(deviceToken: notificationService.deviceToken)
        } catch {
            errorMessage = "알림 상태 변경에 실패했습니다."
        }
    }

    // MARK: - 알림 삭제

    func deleteAlert(_ alert: PriceAlert) async {
        guard let id = alert.id else { return }

        do {
            try await service.deleteAlert(alertId: id)
            alerts.removeAll { $0.id == id }
        } catch {
            errorMessage = "알림 삭제에 실패했습니다."
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

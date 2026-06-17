// NotificationService.swift
// 系统通知服务
// 基于 UserNotifications 框架

import Foundation
import UserNotifications

class NotificationService: ObservableObject {

    // MARK: - Published Properties

    @Published var isEnabled: Bool = false

    // MARK: - Initialization

    init() {
        checkAuthorizationStatus()
    }

    // MARK: - Public Methods

    /// 请求通知权限
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [
            .alert,   // 横幅通知
            .sound    // 声音
            // .badge 未使用（菜单栏应用无需）
        ]

        UNUserNotificationCenter.current().requestAuthorization(
            options: options
        ) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    Logger.shared.error("Notification auth failed: \(error.localizedDescription)")
                    return
                }

                Logger.shared.info("Notification auth granted: \(granted)")
                self?.isEnabled = granted
            }
        }
    }

    /// 发送通知
    func send(title: String, body: String) {
        guard isEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // 立即发送
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.shared.error("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private Methods

    /// 检查当前授权状态
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isEnabled = (settings.authorizationStatus == .authorized)
            }
        }
    }
}

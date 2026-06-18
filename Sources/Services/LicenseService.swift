// LicenseService.swift
// 开源版本 - 无授权限制
// CaffeinatePlus 是一个完全免费开源的项目

import Foundation

class LicenseService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var state: LicenseState = .activated

    // MARK: - Initialization

    init() {
        // 开源版本：直接设置为已激活状态
        state = .activated
        Logger.shared.info("CaffeinatePlus: Open Source - All features unlocked")
    }

    // MARK: - Public Methods

    /// 检查授权状态（开源版本始终返回已激活）
    func checkLicense() {
        state = .activated
    }

    /// 获取授权状态描述
    func statusDescription() -> String {
        return "Open Source - Free Forever"
    }
}

// MARK: - License State

enum LicenseState: Equatable {
    case activated  // 始终激活状态

    var canUseApp: Bool {
        return true  // 开源版本始终可用
    }

    var needsUpgrade: Bool {
        return false  // 开源版本无需升级
    }

    var displayText: String {
        return "Open Source Edition"
    }

    var statusColor: String {
        return "green"
    }
}

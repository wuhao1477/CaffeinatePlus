// AppStateComplete.swift
// 完整版应用主状态管理
// 添加启动项管理和事件处理（对齐原始应用）

import Foundation
import Combine
import SwiftUI
import ServiceManagement

class AppState: ObservableObject {

    // MARK: - Published Properties

    @Published var isActive: Bool = false
    @Published var operationMode: OperationMode = .virtualDisplay
    @Published var displayConfig: DisplayConfig = DisplayConfig.presets[0]
    @Published var notificationsEnabled: Bool = true
    @Published var hotkeyEnabled: Bool = true
    @Published var restoreLastConfig: Bool = false
    @Published var showInDock: Bool = false
    @Published var autoActivateOnLaunch: Bool = false
    @Published private(set) var launchAtLoginEnabled: Bool = false

    // MARK: - Services

    let logger = Logger.shared
    let sleepService = SleepService()
    let clamshellMonitor = ClamshellMonitor()
    let virtualDisplayService = VirtualDisplayService()
    let audioService = AudioService()
    let licenseService = LicenseService()
    let hotkeyService: HotkeyService
    let notificationService = NotificationService()
    let systemMonitorService = SystemMonitorService()

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let defaults = UserDefaults.standard

    // MARK: - Initialization

    init() {
        // 先初始化 hotkeyService（不传回调）
        hotkeyService = HotkeyService()

        // 设置回调（使用正确的属性名 onToggle）
        hotkeyService.onToggle = { [weak self] in
            self?.toggle()
        }

        // 开源版本始终启用全部功能
        licenseService.checkLicense()

        // 从 UserDefaults 加载设置
        loadSettings()

        // 设置服务回调
        setupServiceCallbacks()

        // 自动激活（如果启用）
        if autoActivateOnLaunch {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.activate()
            }
        }

        logger.info("AppState initialized")
    }

    // MARK: - Public Methods

    /// 切换激活状态
    func toggle() {
        if isActive {
            deactivate()
        } else {
            activate()
        }
    }

    /// 激活
    func activate() {
        guard !isActive else { return }

        // 开源版本：移除授权检查，直接激活

        // 根据模式激活服务
        switch operationMode {
        case .preventSleep:
            try? sleepService.preventSleep()

        case .virtualDisplay:
            do {
                try virtualDisplayService.createDisplay(config: displayConfig)
                try? sleepService.preventSleep()
            } catch {
                logger.error("Failed to activate: \(error.localizedDescription)")
                notificationService.send(
                    title: "Activation Failed",
                    body: error.localizedDescription
                )
                return
            }

        case .audioRouting:
            do {
                try audioService.startRouting()
                try? sleepService.preventSleep()
            } catch {
                logger.error("Failed to activate: \(error.localizedDescription)")
                notificationService.send(
                    title: "Activation Failed",
                    body: error.localizedDescription
                )
                return
            }

        case .combined:
            do {
                try virtualDisplayService.createDisplay(config: displayConfig)
                try audioService.startRouting()
                try? sleepService.preventSleep()
            } catch {
                logger.error("Failed to activate: \(error.localizedDescription)")
                deactivate()  // 清理部分成功的服务
                notificationService.send(
                    title: "Activation Failed",
                    body: error.localizedDescription
                )
                return
            }
        }

        isActive = true
        updateActiveState()

        // 发送通知
        if notificationsEnabled {
            notificationService.send(
                title: "CaffeinatePlus Activated",
                body: "Your Mac will stay awake"
            )
        }
    }

    /// 停用
    func deactivate() {
        guard isActive else { return }

        sleepService.allowSleep()
        virtualDisplayService.removeDisplay()
        audioService.stopRouting()

        isActive = false
        updateActiveState()

        // 发送通知
        if notificationsEnabled {
            notificationService.send(
                title: "CaffeinatePlus Deactivated",
                body: "Your Mac can sleep normally"
            )
        }
    }

    /// 切换启动项（对齐原始应用）
    @available(macOS 13.0, *)
    func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp

        do {
            if service.status == .enabled {
                try service.unregister()
                launchAtLoginEnabled = false
                logger.info("Launch at login disabled")
            } else {
                try service.register()
                launchAtLoginEnabled = true
                logger.info("Launch at login enabled")
            }
        } catch {
            logger.error("Failed to toggle launch at login: \(error)")
        }
    }

    // MARK: - Settings Persistence

    /// 保存设置（对齐原始应用）
    private func saveSettings() {
        defaults.set(operationMode.rawValue, forKey: "operationMode")

        if let configData = try? JSONEncoder().encode(displayConfig) {
            defaults.set(configData, forKey: "displayConfig")
        }

        defaults.set(notificationsEnabled, forKey: "notificationsEnabled")
        defaults.set(hotkeyEnabled, forKey: "hotkeyEnabled")
        defaults.set(restoreLastConfig, forKey: "restoreLastConfig")
        defaults.set(showInDock, forKey: "showInDock")
        defaults.set(autoActivateOnLaunch, forKey: "autoActivateOnLaunch")
    }

    /// 加载设置
    private func loadSettings() {
        operationMode = OperationMode(
            rawValue: defaults.string(forKey: "operationMode") ?? ""
        ) ?? .virtualDisplay

        if let configData = defaults.data(forKey: "displayConfig"),
           let config = try? JSONDecoder().decode(DisplayConfig.self, from: configData) {
            displayConfig = config
        }

        notificationsEnabled = defaults.bool(forKey: "notificationsEnabled")
        hotkeyEnabled = defaults.bool(forKey: "hotkeyEnabled")
        restoreLastConfig = defaults.bool(forKey: "restoreLastConfig")
        showInDock = defaults.bool(forKey: "showInDock")
        autoActivateOnLaunch = defaults.bool(forKey: "autoActivateOnLaunch")

        if #available(macOS 13.0, *) {
            launchAtLoginEnabled = SMAppService.mainApp.status == .enabled
        }
    }

    // MARK: - Private Methods（对齐原始应用）

    /// 更新激活状态（对齐原始应用）
    private func updateActiveState() {
        // 触发 UI 更新
        objectWillChange.send()

        // 保存当前状态
        if restoreLastConfig {
            saveSettings()
        }
    }

    /// 处理合盖状态变化（对齐原始应用）
    private func handleClamshellChange(isClosed: Bool) {
        logger.debug("Clamshell state changed: \(isClosed ? "closed" : "open")")

        if isClosed && isActive {
            // 合盖时确保防睡眠仍然生效
            logger.info("Clamshell closed, reinforcing sleep prevention")

            // 重新应用防睡眠断言
            try? sleepService.preventSleep()
        }
    }

    // MARK: - Service Callbacks

    private func setupServiceCallbacks() {
        // 订阅合盖状态变化（对齐原始应用）
        clamshellMonitor.$isClamshellClosed
            .sink { [weak self] isClosed in
                self?.handleClamshellChange(isClosed: isClosed)
            }
            .store(in: &cancellables)

        // 订阅音频路由状态
        audioService.$isRouting
            .sink { [weak self] _ in
                self?.updateActiveState()
            }
            .store(in: &cancellables)

        // 订阅虚拟显示器状态
        virtualDisplayService.$isActive
            .sink { [weak self] _ in
                self?.updateActiveState()
            }
            .store(in: &cancellables)

        // 订阅设置变化，自动保存
        Publishers.CombineLatest4(
            $notificationsEnabled,
            $hotkeyEnabled,
            $showInDock,
            $autoActivateOnLaunch
        )
        .debounce(for: 0.5, scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.saveSettings()
        }
        .store(in: &cancellables)
    }

    // MARK: - Cleanup

    deinit {
        deactivate()
        cancellables.removeAll()
    }
}

// MARK: - Operation Mode

enum OperationMode: String, Codable, Hashable, CaseIterable {
    case preventSleep = "preventSleep"
    case virtualDisplay = "virtualDisplay"
    case audioRouting = "audioRouting"
    case combined = "combined"

    var displayName: String {
        switch self {
        case .preventSleep: return "Prevent Sleep"
        case .virtualDisplay: return "Virtual Display"
        case .audioRouting: return "Audio Routing"
        case .combined: return "Combined Mode"
        }
    }
}

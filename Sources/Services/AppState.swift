// AppStateComplete.swift
// 完整版应用主状态管理
// 添加启动项管理和事件处理（对齐原始应用）

import Combine
import Foundation
import ServiceManagement
import SwiftUI

class AppState: ObservableObject {

  // MARK: - Published Properties

  @Published var isActive: Bool = false
  @Published var operationMode: OperationMode = .preventSleep
  @Published var displayConfig: DisplayConfig = DisplayConfig.presets[0]
  @Published var notificationsEnabled: Bool = true
  @Published var hotkeyEnabled: Bool = true
  @Published var restoreLastConfig: Bool = false
  @Published var automaticClamshellVirtualDisplayEnabled: Bool = true
  @Published var showInDock: Bool = false
  @Published var autoActivateOnLaunch: Bool = false
  @Published var language: AppLanguage = .system
  @Published var theme: AppTheme = .system
  @Published var lastErrorMessage: String?
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
  private let clamshellAutomation = ClamshellAutomation()
  private let clamshellDisplayConfiguration = ClamshellDisplayConfiguration()
  private let clamshellPowerManagement = ClamshellPowerManagement()

  // MARK: - Private Properties

  private var cancellables = Set<AnyCancellable>()
  private let defaults = UserDefaults.standard
  private var didShutdown = false

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
    applyAllSettings()
    if automaticClamshellVirtualDisplayEnabled {
      prepareAutomaticClamshellMode()
    }

    // 设置服务回调
    setupServiceCallbacks()
    setupTerminationCallback()

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
    lastErrorMessage = nil

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
        reportActivationFailure(error.localizedDescription)
        return
      }

    case .audioRouting:
      do {
        try audioService.startRouting()
        try? sleepService.preventSleep()
      } catch {
        reportActivationFailure(error.localizedDescription)
        return
      }

    case .combined:
      do {
        try virtualDisplayService.createDisplay(config: displayConfig)
        try audioService.startRouting()
        try? sleepService.preventSleep()
      } catch {
        reportActivationFailure(error.localizedDescription)
        deactivate()  // 清理部分成功的服务
        return
      }
    }

    isActive = true
    updateActiveState()

    // 发送通知
    if notificationsEnabled {
      notificationService.send(
        title: localized("activated_title"),
        body: localized("activated_body")
      )
    }
  }

  /// 停用
  func deactivate() {
    guard isActive else { return }
    lastErrorMessage = nil

    sleepService.allowSleep()
    virtualDisplayService.removeDisplay()
    audioService.stopRouting()

    isActive = false
    updateActiveState()

    // 发送通知
    if notificationsEnabled {
      notificationService.send(
        title: localized("deactivated_title"),
        body: localized("deactivated_body")
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

  func setPreventDisplaySleep(_ enabled: Bool) {
    sleepService.preventDisplaySleep = enabled
    if !enabled {
      sleepService.preventScreenSaver = false
    }
    updateActiveFlagFromSleepService()
  }

  func setPreventSystemSleep(_ enabled: Bool) {
    sleepService.preventSystemSleep = enabled
    if !enabled {
      sleepService.preventAutoLock = false
    }
    updateActiveFlagFromSleepService()
  }

  func setPreventScreenSaverAndLock(_ enabled: Bool) {
    sleepService.preventScreenSaver = enabled
    sleepService.preventAutoLock = enabled
    updateActiveFlagFromSleepService()
  }

  func setNotificationsEnabled(_ enabled: Bool) {
    notificationsEnabled = enabled
    if enabled {
      notificationService.requestAuthorization()
    }
  }

  func setHotkeyEnabled(_ enabled: Bool) {
    hotkeyEnabled = enabled
    applyHotkeySetting()
  }

  func setShowInDock(_ enabled: Bool) {
    showInDock = enabled
    applyDockSetting()
  }

  func setAutomaticClamshellVirtualDisplayEnabled(_ enabled: Bool) {
    guard automaticClamshellVirtualDisplayEnabled != enabled else { return }
    automaticClamshellVirtualDisplayEnabled = enabled

    if enabled {
      prepareAutomaticClamshellMode()
    } else {
      if let active = clamshellAutomation.lidDidOpen(
        virtualDisplay: virtualDisplayService,
        sleep: sleepService,
        displayConfiguration: clamshellDisplayConfiguration
      ) {
        isActive = active
        updateActiveState()
      }
      clamshellAutomation.cancelPreparedVirtualDisplay(virtualDisplay: virtualDisplayService)
      clamshellPowerManagement.deactivateAutomaticClamshellProtection()
    }

    saveSettings()
  }

  func setLanguage(_ newLanguage: AppLanguage) {
    language = newLanguage
    applyLanguageSetting()
    saveSettings()
  }

  func localized(_ key: String) -> String {
    AppLocalization.localized(key, language: language)
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
    defaults.set(
      automaticClamshellVirtualDisplayEnabled,
      forKey: "automaticClamshellVirtualDisplayEnabled"
    )
    defaults.set(showInDock, forKey: "showInDock")
    defaults.set(autoActivateOnLaunch, forKey: "autoActivateOnLaunch")
    defaults.set(language.rawValue, forKey: "language")
    defaults.set(theme.rawValue, forKey: "theme")
  }

  /// 加载设置
  private func loadSettings() {
    operationMode =
      OperationMode(
        rawValue: defaults.string(forKey: "operationMode") ?? ""
      ) ?? .preventSleep

    if let configData = defaults.data(forKey: "displayConfig"),
      let config = try? JSONDecoder().decode(DisplayConfig.self, from: configData)
    {
      displayConfig = config
    }

    notificationsEnabled = boolSetting("notificationsEnabled", defaultValue: true)
    hotkeyEnabled = boolSetting("hotkeyEnabled", defaultValue: true)
    restoreLastConfig = boolSetting("restoreLastConfig", defaultValue: false)
    automaticClamshellVirtualDisplayEnabled = boolSetting(
      "automaticClamshellVirtualDisplayEnabled",
      defaultValue: true
    )
    showInDock = boolSetting("showInDock", defaultValue: false)
    autoActivateOnLaunch = boolSetting("autoActivateOnLaunch", defaultValue: false)
    language = AppLanguage(rawValue: defaults.string(forKey: "language") ?? "") ?? .system
    theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .system

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

  private func reportActivationFailure(_ message: String) {
    logger.error("Failed to activate: \(message)")
    lastErrorMessage = message
    notificationService.send(title: localized("activation_failed"), body: message)
  }

  private func boolSetting(_ key: String, defaultValue: Bool) -> Bool {
    guard defaults.object(forKey: key) != nil else { return defaultValue }
    return defaults.bool(forKey: key)
  }

  private func updateActiveFlagFromSleepService() {
    let active =
      sleepService.isPreventingAnything || virtualDisplayService.isActive || audioService.isRouting

    if isActive != active {
      isActive = active
    }
    updateActiveState()
  }

  private func applyAllSettings() {
    applyLanguageSetting()
    applyHotkeySetting()
    applyDockSetting()
  }

  private func applyLanguageSetting() {
    if let languages = language.appleLanguagesValue {
      defaults.set(languages, forKey: "AppleLanguages")
    } else {
      defaults.removeObject(forKey: "AppleLanguages")
    }
  }

  private func applyHotkeySetting() {
    if hotkeyEnabled {
      hotkeyService.enable()
    } else {
      hotkeyService.disable()
    }
  }

  private func applyDockSetting() {
    NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
  }

  private func prepareAutomaticClamshellMode() {
    do {
      try clamshellPowerManagement.activateAutomaticClamshellProtection()
    } catch {
      logger.error("Failed to prepare automatic clamshell protection: \(error)")
    }

    do {
      _ = try clamshellAutomation.prepareForLidClose(
        config: displayConfig,
        virtualDisplay: virtualDisplayService
      )
    } catch {
      logger.error("Failed to prepare automatic clamshell virtual display: \(error)")
    }
  }

  /// 处理合盖状态变化（对齐原始应用）
  private func handleClamshellChange(isClosed: Bool) {
    logger.debug("Clamshell state changed: \(isClosed ? "closed" : "open")")

    guard automaticClamshellVirtualDisplayEnabled else {
      logger.debug("Automatic clamshell virtual display is disabled")
      return
    }

    if isClosed {
      do {
        isActive = try clamshellAutomation.lidDidClose(
          config: displayConfig,
          wasAppActive: isActive,
          virtualDisplay: virtualDisplayService,
          sleep: sleepService,
          displayConfiguration: clamshellDisplayConfiguration
        )
        updateActiveState()
      } catch {
        reportActivationFailure(error.localizedDescription)
      }
      return
    }

    if let active = clamshellAutomation.lidDidOpen(
      virtualDisplay: virtualDisplayService,
      sleep: sleepService,
      displayConfiguration: clamshellDisplayConfiguration
    ) {
      isActive = active
      updateActiveState()
    }
  }

  // MARK: - Service Callbacks

  private func setupServiceCallbacks() {
    // 订阅合盖状态变化（对齐原始应用）
    clamshellMonitor.$isClamshellClosed
      .dropFirst()
      .removeDuplicates()
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

    Publishers.CombineLatest4(
      $restoreLastConfig,
      $operationMode,
      $language,
      $theme
    )
    .debounce(for: 0.5, scheduler: DispatchQueue.main)
    .sink { [weak self] _ in
      self?.saveSettings()
    }
    .store(in: &cancellables)
  }

  private func setupTerminationCallback() {
    NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
      .sink { [weak self] _ in
        self?.shutdown()
      }
      .store(in: &cancellables)
  }

  func shutdown() {
    guard !didShutdown else { return }
    didShutdown = true

    deactivate()
    clamshellAutomation.cancelPreparedVirtualDisplay(virtualDisplay: virtualDisplayService)
    clamshellPowerManagement.deactivateAutomaticClamshellProtection()
  }

  // MARK: - Cleanup

  deinit {
    shutdown()
    cancellables.removeAll()
  }
}

// MARK: - Operation Mode

enum OperationMode: String, Codable, Hashable, CaseIterable {
  case preventSleep
  case virtualDisplay
  case audioRouting
  case combined

  var displayName: String {
    displayName(language: .system)
  }

  func displayName(language: AppLanguage) -> String {
    switch self {
    case .preventSleep: return AppLocalization.localized("prevent_sleep", language: language)
    case .virtualDisplay: return AppLocalization.localized("virtual_display", language: language)
    case .audioRouting: return AppLocalization.localized("audio_routing", language: language)
    case .combined: return AppLocalization.localized("combined_mode", language: language)
    }
  }
}

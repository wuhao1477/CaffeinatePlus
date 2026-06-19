// HotkeyServiceFixed.swift
// 改进的全局快捷键服务
// 添加辅助功能权限检查

import AppKit
import Carbon
import Foundation

class HotkeyService {

  // MARK: - Properties

  private var globalMonitor: Any?
  private var hasPermission: Bool = false
  var onToggle: (() -> Void)?

  // MARK: - Constants

  private let keyCodeC: UInt16 = 8
  private let modifiers: NSEvent.ModifierFlags = [.command, .shift]

  // MARK: - Initialization

  init(onToggle: (() -> Void)? = nil) {
    self.onToggle = onToggle
  }

  deinit {
    stopMonitoring()
  }

  // MARK: - Public Methods

  /// 启用快捷键监听
  func enable() {
    if !hasPermission {
      hasPermission = checkAccessibilityPermission()
    }

    if hasPermission {
      startMonitoring()
    } else {
      Logger.shared.warning("Cannot enable hotkey: accessibility permission not granted")
      promptForAccessibilityPermission()
    }
  }

  /// 禁用快捷键监听
  func disable() {
    stopMonitoring()
  }

  /// 手动重新检查权限
  func recheckPermission() -> Bool {
    hasPermission = checkAccessibilityPermission()

    if hasPermission && globalMonitor == nil {
      startMonitoring()
    }

    return hasPermission
  }

  // MARK: - Private Methods

  /// 检查辅助功能权限
  private func checkAccessibilityPermission() -> Bool {
    // 检查当前权限状态（不弹出提示）
    let options: NSDictionary = [
      kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false
    ]
    return AXIsProcessTrustedWithOptions(options)
  }

  /// 提示用户授予辅助功能权限
  private func promptForAccessibilityPermission() {
    // 先显示友好的提示对话框
    DispatchQueue.main.async {
      let alert = NSAlert()
      alert.messageText = AppLocalization.localized("accessibility_permission_title")
      alert.informativeText = AppLocalization.localized("accessibility_permission_body")
      alert.alertStyle = .informational
      alert.addButton(withTitle: AppLocalization.localized("open_system_settings"))
      alert.addButton(withTitle: AppLocalization.localized("later"))

      let response = alert.runModal()

      if response == .alertFirstButtonReturn {
        // 打开系统偏好设置
        if let url = URL(
          string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        {
          NSWorkspace.shared.open(url)
        }
      }
    }

    Logger.shared.info("Accessibility permission prompt shown to user")
  }

  /// 启动快捷键监听
  private func startMonitoring() {
    guard globalMonitor == nil else { return }

    // 注册全局按键监听
    globalMonitor = NSEvent.addGlobalMonitorForEvents(
      matching: .keyDown
    ) { [weak self] event in
      guard let self = self else { return }

      // 检查是否为 Command+Shift+C
      if event.keyCode == self.keyCodeC && event.modifierFlags.contains(self.modifiers) {
        Logger.shared.debug("Hotkey triggered: ⌘⇧C")
        self.onToggle?()
      }
    }

    Logger.shared.info("Hotkey monitoring started (⌘⇧C)")
  }

  /// 停止快捷键监听
  private func stopMonitoring() {
    if let monitor = globalMonitor {
      NSEvent.removeMonitor(monitor)
      globalMonitor = nil
      Logger.shared.info("Hotkey monitoring stopped")
    }
  }
}

// MARK: - Permission Helper

extension HotkeyService {

  /// 打开系统偏好设置的隐私页面
  static func openAccessibilitySettings() {
    let url = URL(
      string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
    NSWorkspace.shared.open(url)
  }

  /// 检查系统级别的辅助功能权限状态
  static func checkSystemPermission() -> Bool {
    let options: NSDictionary = [
      kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false
    ]
    return AXIsProcessTrustedWithOptions(options)
  }
}

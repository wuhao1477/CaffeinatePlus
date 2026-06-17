// MissingPieces.swift
// 遗漏的辅助代码和增强功能
// 包含：枚举增强、常量定义、错误类型、工具方法

import Foundation
import SwiftUI

// MARK: - UserDefaults Keys

extension UserDefaults {
    enum Keys {
        static let operationMode = "operationMode"
        static let displayConfig = "displayConfig"
        static let notificationsEnabled = "notificationsEnabled"
        static let hotkeyEnabled = "hotkeyEnabled"
        static let restoreLastConfig = "restoreLastConfig"
        static let showInDock = "showInDock"
        static let autoActivateOnLaunch = "autoActivateOnLaunch"
        static let firstLaunchDate = "firstLaunchDate"
        static let trial = "trial"
    }
}

// MARK: - Constants

enum Constants {
    enum Window {
        static let width: CGFloat = 400
        static let height: CGFloat = 600
    }

    enum License {
        static let trialDays = 2
        static let hmacSecret = "CaffeinatePlusSecretKey2026"
        static let keychainService = "com.caffeinateplus.app"
        static let keychainAccount = "licenseKey"
    }

    enum Audio {
        static let blackHoleUID = "BlackHole2ch_UID"
        static let aggregateDeviceName = "Caffeinate+ Audio"
    }

    enum Display {
        static let defaultWidth = 1920
        static let defaultHeight = 1080
        static let defaultRefreshRate: Double = 60.0
    }
}

// MARK: - Enhanced Enums

// LicenseState 增强
extension LicenseState {
    var needsUpgrade: Bool {
        self == .expired
    }

    var canUseApp: Bool {
        self == .trial || self == .activated
    }

    var displayText: String {
        switch self {
        case .welcome: return "Welcome"
        case .trial: return "Trial"
        case .activated: return "Activated"
        case .expired: return "Expired"
        }
    }
}

// OperationMode 增强
extension OperationMode {
    var description: String {
        switch self {
        case .preventSleep:
            return "Keep your Mac awake"
        case .virtualDisplay:
            return "Create a virtual display"
        case .audioRouting:
            return "Route audio to virtual device"
        case .combined:
            return "All features enabled"
        }
    }

    var icon: String {
        switch self {
        case .preventSleep: return "moon.zzz.fill"
        case .virtualDisplay: return "display"
        case .audioRouting: return "speaker.wave.2.fill"
        case .combined: return "square.stack.3d.up.fill"
        }
    }
}

// DisplayConfig 增强
extension DisplayConfig {
    var label: String {
        let dpiText = hiDPI ? "HiDPI" : "Standard"
        return "\(width)×\(height) @ \(Int(refreshRate))Hz (\(dpiText))"
    }

    var shortLabel: String {
        let dpiIndicator = hiDPI ? " (2×)" : ""
        return "\(width)×\(height)\(dpiIndicator)"
    }

    var aspectRatio: Double {
        Double(width) / Double(height)
    }

    var megapixels: Double {
        Double(width * height) / 1_000_000.0
    }
}

// PopoverTab 增强（如果在 Views.swift 中定义）
// 这个应该添加到 Views.swift 的 PopoverTab 定义中
/*
extension PopoverTab: Identifiable {
    var id: String { rawValue }

    var title: String {
        switch self {
        case .awake: return "Awake"
        case .display: return "Display"
        case .audio: return "Audio"
        case .monitor: return "Monitor"
        case .settings: return "Settings"
        }
    }
}
*/

// MARK: - Unified Error Type

enum CaffeinateError: LocalizedError {
    case sleepServiceFailed(String)
    case virtualDisplayFailed(String)
    case audioRoutingFailed(String)
    case licenseInvalid
    case trialExpired
    case permissionDenied(String)
    case configurationError(String)
    case unknownError

    var errorDescription: String? {
        switch self {
        case .sleepServiceFailed(let reason):
            return "Failed to prevent sleep: \(reason)"
        case .virtualDisplayFailed(let reason):
            return "Failed to create virtual display: \(reason)"
        case .audioRoutingFailed(let reason):
            return "Failed to route audio: \(reason)"
        case .licenseInvalid:
            return "Invalid license key"
        case .trialExpired:
            return "Trial period has expired. Please activate your license."
        case .permissionDenied(let permission):
            return "Permission denied: \(permission)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .unknownError:
            return "An unknown error occurred"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .sleepServiceFailed:
            return "Try restarting the app or checking system permissions."
        case .virtualDisplayFailed:
            return "Ensure your macOS version supports virtual displays (13.0+)."
        case .audioRoutingFailed:
            return "Check that BlackHole audio driver is installed."
        case .licenseInvalid:
            return "Please check your license key and try again."
        case .trialExpired:
            return "Purchase a license to continue using Caffeinate+."
        case .permissionDenied:
            return "Grant the required permission in System Preferences."
        case .configurationError:
            return "Check your settings and try again."
        case .unknownError:
            return "Contact support if this problem persists."
        }
    }
}

// MARK: - Logger Categories

extension Logger {
    enum Category: String {
        case general = "GENERAL"
        case license = "LICENSE"
        case sleep = "SLEEP"
        case display = "DISPLAY"
        case audio = "AUDIO"
        case ui = "UI"
        case system = "SYSTEM"
    }

    func log(_ message: String, level: LogLevel, category: Category) {
        let prefix = "[\(category.rawValue)]"
        let fullMessage = "\(prefix) \(message)"

        switch level {
        case .debug:
            debug(fullMessage)
        case .info:
            info(fullMessage)
        case .warning:
            warning(fullMessage)
        case .error:
            error(fullMessage)
        }
    }
}

enum LogLevel {
    case debug, info, warning, error
}

// MARK: - Notification Names

extension Notification.Name {
    static let caffeinateActivated = Notification.Name("com.caffeinateplus.activated")
    static let caffeinateDeactivated = Notification.Name("com.caffeinateplus.deactivated")
    static let licenseStateChanged = Notification.Name("com.caffeinateplus.licenseStateChanged")
    static let operationModeChanged = Notification.Name("com.caffeinateplus.operationModeChanged")
    static let displayConfigChanged = Notification.Name("com.caffeinateplus.displayConfigChanged")
}

// MARK: - View Extensions

extension View {
    /// 只在第一次出现时执行
    func onFirstAppear(_ action: @escaping () -> Void) -> some View {
        modifier(FirstAppearModifier(action: action))
    }

    /// 读取视图尺寸
    func readSize(_ size: Binding<CGSize>) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: SizePreferenceKey.self,
                    value: geometry.size
                )
            }
        )
        .onPreferenceChange(SizePreferenceKey.self) { newSize in
            size.wrappedValue = newSize
        }
    }

    /// TextField 占位符
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            if shouldShow {
                placeholder()
            }
            self
        }
    }
}

// MARK: - Supporting Types

struct FirstAppearModifier: ViewModifier {
    let action: () -> Void
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content.onAppear {
            if !hasAppeared {
                hasAppeared = true
                action()
            }
        }
    }
}

struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - String Extensions

extension String {
    /// 安全的本地化
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}

// MARK: - Date Extensions

extension Date {
    func daysFrom(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: self)
        return components.day ?? 0
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }
}

// MARK: - Bundle Extensions

extension Bundle {
    var appName: String {
        infoDictionary?["CFBundleName"] as? String ?? "Caffeinate+"
    }

    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }
}

// MARK: - CGFloat Extensions

extension CGFloat {
    /// 将像素转换为点（考虑屏幕缩放）
    var pixelsToPoints: CGFloat {
        self / (NSScreen.main?.backingScaleFactor ?? 1.0)
    }

    /// 将点转换为像素
    var pointsToPixels: CGFloat {
        self * (NSScreen.main?.backingScaleFactor ?? 1.0)
    }
}

// MARK: - Data Formatters

enum DataFormatter {
    static let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter
    }()

    static func formatBytes(_ bytes: UInt64) -> String {
        byteCountFormatter.string(fromByteCount: Int64(bytes))
    }

    static func formatBytesPerSecond(_ bytesPerSecond: UInt64) -> String {
        formatBytes(bytesPerSecond) + "/s"
    }

    static func formatPercentage(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }

    static func formatUptime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

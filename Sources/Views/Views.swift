// Views.swift
// SwiftUI 视图组件集合

import SwiftUI

// MARK: - PopoverView

struct PopoverView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: PopoverTab = .awake

    var body: some View {
        VStack(spacing: 0) {
            PopoverHeaderView()

            PopoverTabBar(selection: $selectedTab)

            // Tab 内容
            TabView(selection: $selectedTab) {
                AwakeTabView()
                    .tag(PopoverTab.awake)

                DisplayTabView()
                    .tag(PopoverTab.display)

                AudioTabView()
                    .tag(PopoverTab.audio)

                MonitorTabView()
                    .tag(PopoverTab.monitor)

                SettingsTabView()
                    .tag(PopoverTab.settings)
            }
            .tabViewStyle(.automatic)

            PopoverFooterView()
        }
        .frame(width: 400, height: 600)
    }
}

// MARK: - PopoverHeaderView

struct PopoverHeaderView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("CaffeinatePlus")
                .font(.headline)

            Spacer()

            // 状态指示器
            if appState.isActive {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - PopoverFooterView

struct PopoverFooterView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            // 版本信息
            Text("v1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            // 主切换按钮
            Button(action: {
                appState.toggle()
            }) {
                Text(appState.isActive ? "Deactivate" : "Activate")
                    .frame(minWidth: 100)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - PopoverTabBar

struct PopoverTabBar: View {
    @Binding var selection: PopoverTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PopoverTab.allCases, id: \.self) { tab in
                PopoverTabButton(
                    tab: tab,
                    isSelected: selection == tab,
                    action: { selection = tab }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - PopoverTabButton

struct PopoverTabButton: View {
    let tab: PopoverTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))

                Text(tab.title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.accentColor.opacity(0.2) : Color.clear
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .accentColor : .secondary)
    }
}

// MARK: - PopoverTab Enum

enum PopoverTab: String, CaseIterable, Hashable {
    case awake = "awake"
    case display = "display"
    case audio = "audio"
    case monitor = "monitor"
    case settings = "settings"

    var title: String {
        switch self {
        case .awake: return "Awake"
        case .display: return "Display"
        case .audio: return "Audio"
        case .monitor: return "Monitor"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .awake: return "moon.zzz"
        case .display: return "display"
        case .audio: return "speaker.wave.2"
        case .monitor: return "chart.bar"
        case .settings: return "gear"
        }
    }
}

// MARK: - AwakeTabView

struct AwakeTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 许可证过期横幅
                // 开源版本：移除授权横幅

                // 主切换卡片
                masterToggleCard

                // 选项
                optionsSection
            }
            .padding()
        }
    }


    private var masterToggleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading) {
                    Text("Prevent Sleep")
                        .font(.headline)
                    Text(appState.isActive ? "Active" : "Inactive")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { appState.isActive },
                    set: { _ in appState.toggle() }
                ))
                .toggleStyle(.switch)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Options")
                .font(.headline)

            Toggle("Prevent Display Sleep", isOn: $appState.restoreLastConfig)
            Toggle("Prevent System Sleep", isOn: $appState.restoreLastConfig)
            Toggle("Auto-activate on Launch", isOn: $appState.autoActivateOnLaunch)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - DisplayTabView

struct DisplayTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 如果没有虚拟显示器，显示空状态
                if !appState.virtualDisplayService.isActive {
                    emptyStateView
                }

                // 创建虚拟显示器部分
                createDisplaySection
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "display")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Virtual Display")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Extends to the right of your main display")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Create Display Section

    private var createDisplaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Virtual Display")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 16) {
                // Resolution
                HStack {
                    Text("Resolution")
                        .frame(width: 120, alignment: .leading)

                    Spacer()

                    Menu {
                        Button("1080p (1,920x1,080)") {
                            appState.displayConfig = DisplayConfig.presets[0]
                        }
                        Button("1440p (2,560x1,440)") {
                            appState.displayConfig = DisplayConfig.presets[1]
                        }
                        Button("4K (3,840x2,160)") {
                            appState.displayConfig = DisplayConfig.presets[2]
                        }
                    } label: {
                        HStack {
                            Text(appState.displayConfig.shortLabel)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                // Refresh Rate
                HStack {
                    Text("Refresh Rate")
                        .frame(width: 120, alignment: .leading)

                    Spacer()

                    Menu {
                        Button("60 Hz") {
                            var config = appState.displayConfig
                            config.refreshRate = 60
                            appState.displayConfig = config
                        }
                        Button("120 Hz") {
                            var config = appState.displayConfig
                            config.refreshRate = 120
                            appState.displayConfig = config
                        }
                    } label: {
                        HStack {
                            Text("\(Int(appState.displayConfig.refreshRate)) Hz")
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                // HiDPI (Retina)
                HStack {
                    Text("HiDPI (Retina)")
                        .frame(width: 120, alignment: .leading)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { appState.displayConfig.hiDPI },
                        set: { enabled in
                            var config = appState.displayConfig
                            config.hiDPI = enabled
                            appState.displayConfig = config
                        }
                    ))
                    .labelsHidden()
                }

                // Create Button
                Button(action: {
                    if appState.virtualDisplayService.isActive {
                        appState.virtualDisplayService.removeDisplay()
                    } else {
                        try? appState.virtualDisplayService.createDisplay(config: appState.displayConfig)
                    }
                }) {
                    HStack {
                        Image(systemName: appState.virtualDisplayService.isActive ? "minus" : "plus")
                        Text(appState.virtualDisplayService.isActive ? "Remove Virtual Display" : "Create Virtual Display")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            // Quick Presets
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Presets")
                    .font(.headline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    PresetButton(label: "1080p") {
                        appState.displayConfig = DisplayConfig.presets[0]
                    }
                    PresetButton(label: "1440p") {
                        appState.displayConfig = DisplayConfig.presets[1]
                    }
                    PresetButton(label: "4K") {
                        appState.displayConfig = DisplayConfig.presets[2]
                    }
                }
            }
        }
    }
}

// MARK: - PresetButton

struct PresetButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AudioTabView

struct AudioTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 许可证过期横幅
                // 开源版本：移除授权横幅

                // 主内容
                if appState.audioService.isDriverInstalled {
                    driverInstalledView
                } else {
                    driverNotInstalledView
                }
            }
            .padding()
        }
    }

    private var driverInstalledView: some View {
        VStack(spacing: 16) {
            audioToggleCard
            routingDiagram
        }
    }

    private var driverNotInstalledView: some View {
        VStack(spacing: 16) {
            routingDiagram

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Audio Driver Required")
                        .font(.headline)
                }

                Text("BlackHole virtual audio driver is required to route system audio to capture apps like OBS or Zoom.")
                    .multilineTextAlignment(.center)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Install BlackHole") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/ExistentialAudio/BlackHole")!)
                }
                .controlSize(.small)

                Text("Install BlackHole 2ch (free, open-source) to enable audio routing.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    private var audioToggleCard: some View {
        HStack {
            Image(systemName: "speaker.wave.2.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
                .frame(width: 60, height: 60)

            VStack(alignment: .leading) {
                Text("Audio Routing")
                    .font(.headline)
                Text(appState.audioService.isRouting ? "Active" : "Off")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { appState.audioService.isRouting },
                set: { enabled in
                    if enabled {
                        try? appState.audioService.startRouting()
                    } else {
                        appState.audioService.stopRouting()
                    }
                }
            ))
            .toggleStyle(.switch)
            // 开源版本：移除授权限制
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var routingDiagram: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Audio Flow")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 16) {
                // App Audio
                AudioFlowBox(
                    icon: "app.fill",
                    label: "App Audio",
                    color: .blue
                )

                Image(systemName: "arrow.down")
                    .foregroundColor(.secondary)
                    .font(.title3)

                // Aggregate Device
                AudioFlowBox(
                    icon: "rectangle.3.group",
                    label: "Aggregate Device",
                    color: .purple
                )

                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.secondary)
                            .font(.title3)

                        AudioFlowBox(
                            icon: "speaker.wave.2.fill",
                            label: "Speaker",
                            color: .green,
                            subtitle: "You hear"
                        )
                    }

                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down")
                            .foregroundColor(.secondary)
                            .font(.title3)

                        AudioFlowBox(
                            icon: "waveform",
                            label: "BlackHole",
                            color: .orange,
                            subtitle: "Virtual mic"
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            .cornerRadius(12)
        }
    }
}

// MARK: - MonitorTabView

struct MonitorTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                systemInfoSection
                resourceUsageSection
                quickActionsSection
            }
            .padding()
        }
    }

    // MARK: - System Info Section

    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Info")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                SystemInfoRow(
                    icon: "clock",
                    iconColor: .blue,
                    label: "System Uptime",
                    value: formatUptime(appState.systemMonitorService.systemUptime)
                )

                SystemInfoRow(
                    icon: "display",
                    iconColor: .cyan,
                    label: "Connected Displays",
                    value: "\(appState.systemMonitorService.connectedDisplays)"
                )

                SystemInfoRow(
                    icon: "thermometer",
                    iconColor: .green,
                    label: "Thermal State",
                    value: thermalStateText(appState.systemMonitorService.thermalState)
                )

                SystemInfoRow(
                    icon: "battery.100",
                    iconColor: .green,
                    label: "Battery",
                    value: "\(appState.systemMonitorService.batteryLevel)% (\(appState.systemMonitorService.isCharging ? "Charging" : "On Battery"))"
                )
            }
        }
    }

    // MARK: - Resource Usage Section

    private var resourceUsageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resource Usage")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(spacing: 16) {
                // CPU
                ResourceUsageRow(
                    icon: "cpu",
                    label: "CPU",
                    value: appState.systemMonitorService.cpuUsage,
                    percentage: "\(String(format: "%.1f", appState.systemMonitorService.cpuUsage))%",
                    color: .green
                )

                ResourceUsageRow(
                    icon: "memorychip",
                    label: "Memory",
                    value: percent(
                        used: appState.systemMonitorService.memoryUsed,
                        total: appState.systemMonitorService.memoryTotal
                    ),
                    percentage: capacityText(
                        used: appState.systemMonitorService.memoryUsed,
                        total: appState.systemMonitorService.memoryTotal,
                        fractionDigits: 2
                    ),
                    color: .orange
                )

                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "internaldrive")
                            .foregroundColor(.secondary)
                        Text("Disk")
                        Spacer()
                        Text(capacityText(
                            used: appState.systemMonitorService.diskUsed,
                            total: appState.systemMonitorService.diskTotal,
                            fractionDigits: 0
                        ))
                            .foregroundColor(.secondary)
                    }

                    ProgressView(
                        value: percent(
                            used: appState.systemMonitorService.diskUsed,
                            total: appState.systemMonitorService.diskTotal
                        ),
                        total: 100
                    )
                        .tint(.orange)
                }
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "arrow.clockwise",
                    label: "Refresh",
                    action: {
                        appState.systemMonitorService.refresh()
                    }
                )

                QuickActionButton(
                    icon: "chart.bar.fill",
                    label: "Activity",
                    action: {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                    }
                )

                QuickActionButton(
                    icon: "info.circle",
                    label: "System Info",
                    action: {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/System Information.app"))
                    }
                )
            }
        }
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86400
        let hours = (Int(seconds) % 86400) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return "\(days)d \(hours)h \(minutes)m"
    }

    private func percent(used: UInt64, total: UInt64) -> Double {
        guard total > 0 else { return 0 }
        return min(100, (Double(used) / Double(total)) * 100)
    }

    private func capacityText(used: UInt64, total: UInt64, fractionDigits: Int) -> String {
        guard total > 0 else { return "Unavailable" }
        let divisor = 1_073_741_824.0
        let usedGB = Double(used) / divisor
        let totalGB = Double(total) / divisor
        return String(format: "%.*f GB / %.*f GB", fractionDigits, usedGB, fractionDigits, totalGB)
    }

    private func thermalStateText(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "Normal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - SettingsTabView

struct SettingsTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 许可证部分
                licenseSection

                // 通用设置
                generalSettings

                // 高级设置
                advancedSettings
            }
            .padding()
        }
    }

    private var licenseSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("About")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            VStack(alignment: .leading, spacing: 12) {
                // 应用名称和版本
                HStack {
                    Text("CaffeinatePlus")
                        .font(.body)
                    Spacer()
                    Text("v2.0.0")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                Divider()

                // CGVirtualDisplay API 状态
                HStack {
                    Text("CGVirtualDisplay API")
                        .font(.body)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Available")
                            .foregroundColor(.green)
                    }
                }

                Divider()

                // Lid State
                HStack {
                    Text("Lid State")
                        .font(.body)
                    Spacer()
                    Text("Open")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("General")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            VStack(spacing: 0) {
                // Launch at Login
                SettingRow(
                    icon: "arrow.right.circle",
                    title: "Launch at Login",
                    description: "Start automatically on login",
                    isOn: Binding(
                        get: { appState.launchAtLoginEnabled },
                        set: { _ in
                            if #available(macOS 13.0, *) {
                                appState.toggleLaunchAtLogin()
                            }
                        }
                    )
                )

                Divider()
                    .padding(.leading, 60)

                // Restore Last Config
                SettingRow(
                    icon: "arrow.counterclockwise",
                    title: "Restore Last Config",
                    description: "Resume previous state on launch",
                    isOn: $appState.restoreLastConfig
                )

                Divider()
                    .padding(.leading, 60)

                // Global Hotkey
                SettingRow(
                    icon: "keyboard",
                    title: "Global Hotkey",
                    description: "Cmd+Shift+C to toggle",
                    isOn: $appState.hotkeyEnabled
                )

                Divider()
                    .padding(.leading, 60)

                // Notifications
                SettingRow(
                    icon: "bell",
                    title: "Notifications",
                    description: "Status change alerts",
                    isOn: $appState.notificationsEnabled
                )

                Divider()
                    .padding(.leading, 60)

                // Show in Dock
                SettingRow(
                    icon: "rectangle.dock",
                    title: "Show in Dock",
                    description: "Display app icon in Dock",
                    isOn: $appState.showInDock
                )

                Divider()
                    .padding(.leading, 60)

                // Auto Activate on Launch
                SettingRow(
                    icon: "bolt",
                    title: "Auto Activate on Launch",
                    description: "Activate all features after reboot",
                    isOn: $appState.autoActivateOnLaunch
                )
            }
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    private var advancedSettings: some View {
        VStack(spacing: 0) {
            // 退出按钮
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                        .font(.title3)
                    Text("Quit")
                        .font(.body)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .foregroundColor(.primary)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

// MARK: - SettingRow

struct SystemInfoRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            Text(label)
                .font(.body)
            Spacer()
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct ResourceUsageRow: View {
    let icon: String
    let label: String
    let value: Double
    let percentage: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Text(label)
                Spacer()
                Text(percentage)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: value, total: 100)
                .tint(color)
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SettingRow

struct SettingRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            // 图标
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.secondary)
                .frame(width: 32)

            // 标题和描述
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Toggle 开关
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Custom Toggle Style

struct CompactToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                Spacer()
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - AudioFlowBox

struct AudioFlowBox: View {
    let icon: String
    let label: String
    let color: Color
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(label)
                .font(.body)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

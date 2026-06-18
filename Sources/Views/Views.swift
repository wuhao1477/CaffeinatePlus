// Views.swift
// SwiftUI 视图组件集合

import SwiftUI

// MARK: - PopoverView

struct PopoverView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: PopoverTab = .display

    var body: some View {
        VStack(spacing: 0) {
            PopoverHeaderView()

            Divider()

            PopoverTabBar(selection: $selectedTab)

            Divider()

            Group {
                switch selectedTab {
                case .awake:
                    AwakeTabView()
                case .display:
                    DisplayTabView()
                case .audio:
                    AudioTabView()
                case .monitor:
                    MonitorTabView()
                case .settings:
                    SettingsTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            PopoverFooterView()
        }
        .background(Color(NSColor.windowBackgroundColor))
        .frame(width: 320, height: 460)
    }
}

// MARK: - PopoverHeaderView

struct PopoverHeaderView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 25, weight: .semibold))
                .foregroundColor(.blue)

            Text("CaffeinatePlus")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(appState.isActive ? Color.green : Color.orange)
                    .frame(width: 8, height: 8)
                Text(appState.isActive ? "Active" : "Idle")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 44)
    }
}

// MARK: - PopoverFooterView

struct PopoverFooterView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text("Open Source")
                    .font(.system(size: 12, weight: .regular))
            }
            .foregroundColor(.orange)

            Spacer()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "power")
                    Text("Quit")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .frame(height: 31)
        .overlay(alignment: .top) { Divider() }
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
        .padding(.horizontal, 16)
        .frame(height: 64)
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
                    .font(.system(size: 23, weight: .regular))

                Text(tab.title)
                    .font(.system(size: 11, weight: .regular))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 49)
            .background(
                isSelected ? Color.blue.opacity(0.12) : Color.clear
            )
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .foregroundColor(isSelected ? .blue : .secondary)
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
            VStack(alignment: .leading, spacing: 24) {
                emptyStateView
                createDisplaySection
                quickPresetsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 25)
            .padding(.bottom, 18)
        }
    }

    private var emptyStateView: some View {
        HStack(spacing: 16) {
            Image(systemName: "display")
                .font(.system(size: 34, weight: .regular))
                .foregroundColor(.secondary)
                .frame(width: 54)

            VStack(alignment: .leading, spacing: 4) {
                Text(appState.virtualDisplayService.isActive ? "Virtual Display Active" : "No Virtual Display")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)

                Text(appState.virtualDisplayService.isActive ? "Extending your desktop" : "Extends to the right of your main display")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private var createDisplaySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Create Virtual Display")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                optionRow(title: "Resolution") {
                    Picker("", selection: Binding(
                        get: { selectedPresetIndex },
                        set: { appState.displayConfig = DisplayConfig.presets[$0] }
                    )) {
                        Text("1080p (1,920x1,080)").tag(0)
                        Text("1440p (2,560x1,440)").tag(1)
                        Text("4K (3,840x2,160)").tag(2)
                    }
                    .labelsHidden()
                    .frame(width: 162)
                }

                Divider().padding(.leading, 46)

                optionRow(title: "Refresh Rate") {
                    Picker("", selection: Binding(
                        get: { Int(appState.displayConfig.refreshRate) },
                        set: { refreshRate in
                            var config = appState.displayConfig
                            config.refreshRate = Double(refreshRate)
                            appState.displayConfig = config
                        }
                    )) {
                        Text("60 Hz").tag(60)
                        Text("120 Hz").tag(120)
                    }
                    .labelsHidden()
                    .frame(width: 90)
                }

                Divider().padding(.leading, 46)

                optionRow(title: "HiDPI (Retina)") {
                    Toggle("", isOn: Binding(
                        get: { appState.displayConfig.hiDPI },
                        set: { enabled in
                            var config = appState.displayConfig
                            config.hiDPI = enabled
                            appState.displayConfig = config
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                }
            }

            Button(action: toggleVirtualDisplay) {
                HStack(spacing: 12) {
                    Image(systemName: appState.virtualDisplayService.isActive ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text(appState.virtualDisplayService.isActive ? "Remove Virtual Display" : "Create Virtual Display")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.blue)
                .cornerRadius(22)
            }
            .buttonStyle(.plain)
        }
    }

    private var quickPresetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                presetButton("1080p", index: 0)
                presetButton("1440p", index: 1)
                presetButton("4K", index: 2)
            }
        }
    }

    private var selectedPresetIndex: Int {
        DisplayConfig.presets.firstIndex(where: { preset in
            preset.width == appState.displayConfig.width &&
            preset.height == appState.displayConfig.height &&
            preset.hiDPI == appState.displayConfig.hiDPI
        }) ?? 0
    }

    private func optionRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)

            Spacer()

            content()
        }
        .frame(height: 41)
    }

    private func presetButton(_ title: String, index: Int) -> some View {
        Button(action: { appState.displayConfig = DisplayConfig.presets[index] }) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(selectedPresetIndex == index ? .white : .blue)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(selectedPresetIndex == index ? Color.blue : Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func toggleVirtualDisplay() {
        if appState.virtualDisplayService.isActive {
            appState.virtualDisplayService.removeDisplay()
        } else {
            try? appState.virtualDisplayService.createDisplay(config: appState.displayConfig)
        }
    }

}

// MARK: - AudioTabView

struct AudioTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                routingDiagram
                driverWarningCard

                if !appState.audioService.isDriverInstalled {
                    Text("Install BlackHole 2ch (free, open-source) to enable audio routing.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button(action: openBlackHoleDownload) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Install BlackHole")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue)
                        .cornerRadius(22)
                    }
                    .buttonStyle(.plain)

                    Button(action: refreshDriverDetection) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13))
                            Text("Refresh Detection")
                                .font(.system(size: 13, weight: .regular))
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 26)
            .padding(.bottom, 20)
        }
    }

    private var routingDiagram: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Audio Flow")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)

            VStack(spacing: 9) {
                audioFlowPill(icon: "app.fill", title: "App Audio", color: .blue, background: Color.blue.opacity(0.08))

                Image(systemName: "arrow.down")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)

                audioFlowPill(icon: "rectangle.3.group", title: "Aggregate Device", color: .pink, background: Color.pink.opacity(0.09))

                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        audioFlowPill(icon: "speaker.wave.2", title: "Speaker", color: .green, background: Color.green.opacity(0.09))
                        Text("You hear")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        audioFlowPill(icon: "waveform", title: "BlackHole", color: .orange, background: Color.orange.opacity(0.09))
                        Text("Virtual mic")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var driverWarningCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                Text("Audio Driver Required")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.orange)
            }

            Text("BlackHole virtual audio driver is required to route system audio to capture apps like OBS or Zoom.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(Color.orange.opacity(0.09))
        .cornerRadius(12)
    }

    private func audioFlowPill(icon: String, title: String, color: Color, background: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .frame(height: 23)
        .background(background)
        .cornerRadius(6)
    }

    private func openBlackHoleDownload() {
        if let url = URL(string: "https://github.com/ExistentialAudio/BlackHole") {
            NSWorkspace.shared.open(url)
        }
    }

    private func refreshDriverDetection() {
        appState.audioService.refreshDriverInstallation()
    }
}

// MARK: - MonitorTabView

struct MonitorTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 23) {
                systemInfoSection
                resourceUsageSection
                quickActionsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 22)
        }
    }

    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("System Info")

            VStack(spacing: 0) {
                monitorInfoRow(icon: "clock", color: .blue, title: "System Uptime", value: formatUptimeLong(appState.systemMonitorService.systemUptime))
                Divider().padding(.leading, 42)
                monitorInfoRow(icon: "display", color: .cyan, title: "Connected Displays", value: "\(appState.systemMonitorService.connectedDisplays)")
                Divider().padding(.leading, 42)
                monitorInfoRow(icon: "thermometer", color: .green, title: "Thermal State", value: thermalStateText(appState.systemMonitorService.thermalState), valueColor: .green)
                Divider().padding(.leading, 42)
                monitorInfoRow(
                    icon: "battery.100",
                    color: .green,
                    title: "Battery",
                    value: "\(appState.systemMonitorService.batteryLevel)% (\(appState.systemMonitorService.isCharging ? "Charging" : "On Battery"))",
                    valueColor: .green
                )
            }
        }
    }

    private var resourceUsageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Resource Usage")

            VStack(spacing: 13) {
                resourceRow(
                    icon: "cpu",
                    title: "CPU",
                    valueText: String(format: "%.1f%%", appState.systemMonitorService.cpuUsage),
                    percent: appState.systemMonitorService.cpuUsage,
                    color: .green
                )

                resourceRow(
                    icon: "memorychip",
                    title: "Memory",
                    valueText: capacityText(used: appState.systemMonitorService.memoryUsed, total: appState.systemMonitorService.memoryTotal, fractionDigits: 2),
                    percent: percent(used: appState.systemMonitorService.memoryUsed, total: appState.systemMonitorService.memoryTotal),
                    color: .orange
                )

                resourceRow(
                    icon: "internaldrive",
                    title: "Disk",
                    valueText: capacityText(used: appState.systemMonitorService.diskUsed, total: appState.systemMonitorService.diskTotal, fractionDigits: 0),
                    percent: percent(used: appState.systemMonitorService.diskUsed, total: appState.systemMonitorService.diskTotal),
                    color: .orange
                )
            }

            HStack(spacing: 28) {
                ioRateView(icon: "arrow.down.circle", color: .green, label: "R:", value: formatRate(appState.systemMonitorService.diskReadRate))
                ioRateView(icon: "arrow.up.circle", color: .orange, label: "W:", value: formatRate(appState.systemMonitorService.diskWriteRate))
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Quick Actions")

            HStack(spacing: 32) {
                quickAction(icon: "arrow.clockwise", label: "Refresh") {
                    appState.systemMonitorService.refresh()
                }
                quickAction(icon: "chart.bar", label: "Activity") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                }
                quickAction(icon: "info.circle", label: "System Info") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/System Information.app"))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.secondary)
    }

    private func monitorInfoRow(icon: String, color: Color, title: String, value: String, valueColor: Color = .primary) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 30)
            Text(title)
                .font(.system(size: 13))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(valueColor)
        }
        .frame(height: 32)
    }

    private func resourceRow(icon: String, title: String, valueText: String, percent: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 30)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
                Text(valueText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.08))
                    Capsule().fill(color).frame(width: proxy.size.width * min(max(percent, 0), 100) / 100)
                }
            }
            .frame(height: 5)
            .padding(.leading, 30)
        }
    }

    private func ioRateView(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
        }
    }

    private func quickAction(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func formatUptimeLong(_ seconds: TimeInterval) -> String {
        let days = Int(seconds) / 86_400
        let hours = (Int(seconds) % 86_400) / 3_600
        let minutes = (Int(seconds) % 3_600) / 60
        return "\(days)d \(hours)h \(minutes)m"
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

    private func formatRate(_ bytesPerSecond: UInt64) -> String {
        if bytesPerSecond < 1_024 {
            return "\(bytesPerSecond) B/s"
        }
        if bytesPerSecond < 1_048_576 {
            return String(format: "%.1f KB/s", Double(bytesPerSecond) / 1_024)
        }
        return String(format: "%.1f MB/s", Double(bytesPerSecond) / 1_048_576)
    }
}

// MARK: - SettingsTabView

struct SettingsTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                generalSettings
                aboutSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 22)
        }
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                settingRow(
                    icon: "arrow.right.circle",
                    title: "Launch at Login",
                    subtitle: "Start automatically on login",
                    isOn: Binding(
                        get: { appState.launchAtLoginEnabled },
                        set: { _ in
                            if #available(macOS 13.0, *) {
                                appState.toggleLaunchAtLogin()
                            }
                        }
                    )
                )
                Divider().padding(.leading, 46)

                settingRow(
                    icon: "arrow.counterclockwise",
                    title: "Restore Last Config",
                    subtitle: "Resume previous state on launch",
                    isOn: $appState.restoreLastConfig
                )
                Divider().padding(.leading, 46)

                settingRow(
                    icon: "keyboard",
                    title: "Global Hotkey",
                    subtitle: "Cmd+Shift+C to toggle",
                    isOn: $appState.hotkeyEnabled
                )
                Divider().padding(.leading, 46)

                settingRow(
                    icon: "bell",
                    title: "Notifications",
                    subtitle: "Status change alerts",
                    isOn: $appState.notificationsEnabled
                )
                Divider().padding(.leading, 46)

                settingRow(
                    icon: "rectangle.dock",
                    title: "Show in Dock",
                    subtitle: "Display app icon in Dock",
                    isOn: $appState.showInDock
                )
                Divider().padding(.leading, 46)

                settingRow(
                    icon: "bolt.circle",
                    title: "Auto Activate on Launch",
                    subtitle: "Activate all features after reboot",
                    isOn: $appState.autoActivateOnLaunch
                )
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                aboutRow(title: "CaffeinatePlus", value: "v2.0.0")
                Divider().padding(.leading, 46)
                aboutRow(title: "License", value: appState.licenseService.state.displayText, valueColor: .green)
                Divider().padding(.leading, 46)
                aboutRow(title: "Logs", value: "Open") {
                    let logsURL = FileManager.default.urls(
                        for: .applicationSupportDirectory,
                        in: .userDomainMask
                    )[0]
                    .appendingPathComponent("CaffeinatePlus")
                    .appendingPathComponent("Logs")

                    NSWorkspace.shared.open(logsURL)
                }
            }
        }
    }

    private func settingRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
        }
        .frame(height: 44)
    }

    private func aboutRow(title: String, value: String, valueColor: Color = .secondary, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                Image(systemName: action == nil ? "info.circle" : "folder")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 30)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                Spacer()
                Text(value)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(valueColor)
            }
            .frame(height: 36)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
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

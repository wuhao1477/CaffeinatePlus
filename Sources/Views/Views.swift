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
        VStack(spacing: 8) {
            diagramRow(icon: "desktopcomputer", label: "System Audio", color: .blue)

            Image(systemName: "arrow.down")
                .foregroundColor(.secondary)

            diagramRow(icon: "speaker", label: "Speaker + BlackHole", color: .green)

            HStack {
                VStack {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    diagramRow(icon: "speaker", label: "Output", color: .gray)
                    Text("Real speakers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack {
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    diagramRow(icon: "mic", label: "Virtual Mic", color: .orange)
                    Text("OBS, Zoom, etc.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func diagramRow(icon: String, label: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
        }
    }
}

// MARK: - MonitorTabView

struct MonitorTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                systemInfoCard
                powerInfoCard
                displayInfoCard
            }
            .padding()
        }
    }

    private var systemInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Information")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                infoRow("CPU Usage", value: "\(Int(appState.systemMonitorService.cpuUsage))%")
                infoRow("Memory", value: formatBytes(appState.systemMonitorService.memoryUsed))
                infoRow("Disk", value: formatBytes(appState.systemMonitorService.diskUsed))
                infoRow("Uptime", value: formatUptime(appState.systemMonitorService.systemUptime))
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var powerInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Power")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                infoRow("Battery", value: "\(appState.systemMonitorService.batteryLevel)%")
                infoRow("Status", value: appState.systemMonitorService.isCharging ? "Charging" : "On Battery")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var displayInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Displays")
                .font(.headline)

            infoRow("Connected", value: "\(appState.systemMonitorService.connectedDisplays)")
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
        .font(.caption)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        return "\(hours)h"
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
        VStack(alignment: .leading, spacing: 12) {
            Text("License")
                .font(.headline)

            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text(appState.licenseService.state.displayText)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.headline)

            Toggle("Enable Notifications", isOn: $appState.notificationsEnabled)
            Toggle("Enable Hotkey (⌘⇧C)", isOn: $appState.hotkeyEnabled)
            Toggle("Show in Dock", isOn: $appState.showInDock)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var advancedSettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced")
                .font(.headline)

            Toggle("Restore Last Config", isOn: $appState.restoreLastConfig)
            Toggle("Auto-activate on Launch", isOn: $appState.autoActivateOnLaunch)
            Toggle("Launch at Login", isOn: Binding(
                get: { appState.launchAtLoginEnabled },
                set: { _ in
                    if #available(macOS 13.0, *) {
                        appState.toggleLaunchAtLogin()
                    }
                }
            ))

            Button("View Logs") {
                let logsURL = FileManager.default.urls(
                    for: .applicationSupportDirectory,
                    in: .userDomainMask
                )[0]
                .appendingPathComponent("CaffeinatePlus")
                .appendingPathComponent("Logs")

                NSWorkspace.shared.open(logsURL)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
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

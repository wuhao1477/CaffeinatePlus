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
            VStack(spacing: 16) {
                // 虚拟显示器切换
                virtualDisplayToggleCard

                // 配置选项
                if appState.virtualDisplayService.isActive {
                    configurationSection
                }
            }
            .padding()
        }
    }

    private var virtualDisplayToggleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "display")
                    .font(.largeTitle)
                    .foregroundColor(.purple)
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading) {
                    Text("Virtual Display")
                        .font(.headline)
                    Text(appState.virtualDisplayService.isActive ? "Active" : "Inactive")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { appState.virtualDisplayService.isActive },
                    set: { enabled in
                        if enabled {
                            try? appState.virtualDisplayService.createDisplay(
                                config: appState.displayConfig
                            )
                        } else {
                            appState.virtualDisplayService.removeDisplay()
                        }
                    }
                ))
                .toggleStyle(.switch)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)

            if let config = appState.virtualDisplayService.currentConfig {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Resolution: \(config.width) × \(config.height)")
                    Text("HiDPI: \(config.hiDPI ? "Yes" : "No")")
                    Text("Refresh Rate: \(Int(config.refreshRate)) Hz")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
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

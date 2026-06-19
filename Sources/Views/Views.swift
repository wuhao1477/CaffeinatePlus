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
        Text(appState.localized(appState.isActive ? "active" : "idle"))
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
        Text(Bundle.main.footerVersionText)
          .font(.system(size: 12, weight: .regular))
      }
      .foregroundColor(.orange)

      Spacer()

      Button(
        action: { NSApplication.shared.terminate(nil) },
        label: {
          HStack(spacing: 5) {
            Image(systemName: "power")
            Text(appState.localized("quit"))
          }
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(.secondary)
        }
      )
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
  @EnvironmentObject var appState: AppState

  let tab: PopoverTab
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: tab.icon)
          .font(.system(size: 23, weight: .regular))

        Text(appState.localized(tab.titleKey))
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
  case awake
  case display
  case audio
  case monitor
  case settings

  var titleKey: String {
    switch self {
    case .awake: return "prevent_sleep"
    case .display: return "display"
    case .audio: return "audio"
    case .monitor: return "monitor"
    case .settings: return "settings"
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
      VStack(alignment: .leading, spacing: 0) {
        if let message = appState.lastErrorMessage {
          ErrorBanner(message: message) {
            appState.lastErrorMessage = nil
          }
          .padding(.horizontal, 16)
          .padding(.top, 16)
        }

        primaryToggleCard

        optionsSection
      }
    }
  }

  private var primaryToggleCard: some View {
    HStack(alignment: .center, spacing: 16) {
      Image(systemName: "bolt.fill")
        .font(.system(size: 32, weight: .semibold))
        .foregroundColor(.blue)
        .frame(width: 56, height: 56)

      VStack(alignment: .leading, spacing: 4) {
        Text(appState.localized("awake"))
          .font(.system(size: 15, weight: .bold))
          .foregroundColor(.primary)

        Text(appState.localized(appState.isActive ? "system_kept_awake" : "system_can_sleep"))
          .font(.system(size: 12, weight: .regular))
          .foregroundColor(.secondary)
          .lineLimit(1)
      }

      Spacer(minLength: 12)

      Toggle(
        "",
        isOn: Binding(
          get: { appState.isActive },
          set: { _ in appState.toggle() }
        )
      )
      .labelsHidden()
      .toggleStyle(.switch)
      .frame(width: 46, alignment: .trailing)
    }
    .padding(.horizontal, 20)
    .padding(.top, 28)
    .padding(.bottom, 30)
  }

  private var optionsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(appState.localized("options"))
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.secondary)
        .padding(.horizontal, 20)

      VStack(spacing: 0) {
        AwakeOptionRow(
          icon: "display",
          title: appState.localized("prevent_display_sleep"),
          subtitle: appState.localized("prevent_display_sleep_subtitle"),
          isOn: Binding(
            get: { appState.sleepService.preventDisplaySleep },
            set: { appState.setPreventDisplaySleep($0) }
          )
        )

        Divider().padding(.leading, 62)

        AwakeOptionRow(
          icon: "laptopcomputer",
          title: appState.localized("prevent_system_sleep"),
          subtitle: appState.localized("prevent_system_sleep_subtitle"),
          isOn: Binding(
            get: { appState.sleepService.preventSystemSleep },
            set: { appState.setPreventSystemSleep($0) }
          )
        )

        Divider().padding(.leading, 62)

        AwakeOptionRow(
          icon: "cursorarrow",
          title: appState.localized("prevent_screen_saver_lock"),
          subtitle: appState.localized("prevent_screen_saver_lock_subtitle"),
          isOn: Binding(
            get: { appState.sleepService.preventScreenSaver || appState.sleepService.preventAutoLock },
            set: { appState.setPreventScreenSaverAndLock($0) }
          )
        )
      }
      .padding(.horizontal, 20)
    }
  }
}

private struct AwakeOptionRow: View {
  let icon: String
  let title: String
  let subtitle: String
  @Binding var isOn: Bool

  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      Image(systemName: icon)
        .font(.system(size: 19, weight: .regular))
        .foregroundColor(.secondary)
        .frame(width: 34, height: 34)

      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(.primary)
          .lineLimit(1)
          .minimumScaleFactor(0.9)

        Text(subtitle)
          .font(.system(size: 12, weight: .regular))
          .foregroundColor(.secondary)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
      }

      Spacer(minLength: 12)

      Toggle("", isOn: $isOn)
        .labelsHidden()
        .toggleStyle(.switch)
        .frame(width: 46, alignment: .trailing)
    }
    .frame(minHeight: 44)
    .padding(.vertical, 6)
  }
}

// MARK: - DisplayTabView

struct DisplayTabView: View {
  @EnvironmentObject var appState: AppState

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        if let message = appState.lastErrorMessage {
          ErrorBanner(message: message) {
            appState.lastErrorMessage = nil
          }
        }

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
        Text(
          appState.localized(
            appState.virtualDisplayService.isActive
              ? "virtual_display_active" : "no_virtual_display")
        )
        .font(.system(size: 15, weight: .bold))
        .foregroundColor(.primary)

        Text(
          appState.localized(
            appState.virtualDisplayService.isActive ? "extending_desktop" : "extends_right")
        )
        .font(.system(size: 12, weight: .regular))
        .foregroundColor(.secondary)
        .lineLimit(2)
      }

      Spacer()
    }
  }

  private var createDisplaySection: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text(appState.localized("create_virtual_display"))
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.secondary)

      VStack(spacing: 0) {
        optionRow(title: appState.localized("resolution")) {
          Picker(
            "",
            selection: Binding(
              get: { selectedPresetIndex },
              set: { appState.displayConfig = DisplayConfig.presets[$0] }
            )
          ) {
            Text("1080p (1,920x1,080)").tag(0)
            Text("1440p (2,560x1,440)").tag(1)
            Text("4K (3,840x2,160)").tag(2)
          }
          .labelsHidden()
          .frame(width: 162)
        }

        Divider().padding(.leading, 46)

        optionRow(title: appState.localized("refresh_rate")) {
          Picker(
            "",
            selection: Binding(
              get: { Int(appState.displayConfig.refreshRate) },
              set: { refreshRate in
                var config = appState.displayConfig
                config.refreshRate = Double(refreshRate)
                appState.displayConfig = config
              }
            )
          ) {
            Text("60 Hz").tag(60)
            Text("120 Hz").tag(120)
          }
          .labelsHidden()
          .frame(width: 90)
        }

        Divider().padding(.leading, 46)

        optionRow(title: appState.localized("hidpi")) {
          Toggle(
            "",
            isOn: Binding(
              get: { appState.displayConfig.hiDPI },
              set: { enabled in
                var config = appState.displayConfig
                config.hiDPI = enabled
                appState.displayConfig = config
              }
            )
          )
          .labelsHidden()
          .toggleStyle(.switch)
        }
      }

      Button(action: toggleVirtualDisplay) {
        HStack(spacing: 12) {
          Image(
            systemName: appState.virtualDisplayService.isActive
              ? "minus.circle.fill" : "plus.circle.fill"
          )
          .font(.system(size: 13, weight: .semibold))
          Text(
            appState.localized(
              appState.virtualDisplayService.isActive
                ? "remove_virtual_display" : "create_virtual_display")
          )
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
      Text(appState.localized("quick_presets"))
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
      preset.width == appState.displayConfig.width && preset.height == appState.displayConfig.height
        && preset.hiDPI == appState.displayConfig.hiDPI
    }) ?? 0
  }

  private func optionRow<Content: View>(title: String, @ViewBuilder content: () -> Content)
    -> some View
  {
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
    Button(
      action: { appState.displayConfig = DisplayConfig.presets[index] },
      label: {
        Text(title)
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(selectedPresetIndex == index ? .white : .blue)
          .frame(maxWidth: .infinity)
          .frame(height: 32)
          .background(selectedPresetIndex == index ? Color.blue : Color.blue.opacity(0.1))
          .cornerRadius(8)
      }
    )
    .buttonStyle(.plain)
  }

  private func toggleVirtualDisplay() {
    if appState.virtualDisplayService.isActive {
      appState.virtualDisplayService.removeDisplay()
    } else {
      do {
        try appState.virtualDisplayService.createDisplay(config: appState.displayConfig)
      } catch {
        appState.lastErrorMessage = error.localizedDescription
      }
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
          Text(appState.localized("install_blackhole_body"))
            .font(.system(size: 13, weight: .regular))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

          Button(action: openBlackHoleDownload) {
            HStack(spacing: 12) {
              Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 13, weight: .semibold))
              Text(appState.localized("install_blackhole"))
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
              Text(appState.localized("refresh_detection"))
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
      Text(appState.localized("audio_flow"))
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.secondary)

      VStack(spacing: 9) {
        audioFlowPill(
          icon: "app.fill", title: appState.localized("app_audio"), color: .blue,
          background: Color.blue.opacity(0.08))

        Image(systemName: "arrow.down")
          .font(.system(size: 15))
          .foregroundColor(.secondary)

        audioFlowPill(
          icon: "rectangle.3.group", title: "Aggregate Device", color: .pink,
          background: Color.pink.opacity(0.09))

        HStack(spacing: 32) {
          VStack(spacing: 4) {
            Image(systemName: "arrow.down")
              .font(.system(size: 15))
              .foregroundColor(.secondary)
            audioFlowPill(
              icon: "speaker.wave.2", title: appState.localized("speaker"), color: .green,
              background: Color.green.opacity(0.09))
            Text(appState.localized("you_hear"))
              .font(.system(size: 12))
              .foregroundColor(.secondary)
          }

          VStack(spacing: 4) {
            Image(systemName: "arrow.down")
              .font(.system(size: 15))
              .foregroundColor(.secondary)
            audioFlowPill(
              icon: "waveform", title: "BlackHole", color: .orange,
              background: Color.orange.opacity(0.09))
            Text(appState.localized("virtual_mic"))
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
        Text(appState.localized("audio_driver_required"))
          .font(.system(size: 15, weight: .bold))
          .foregroundColor(.orange)
      }

      Text(appState.localized("blackhole_required_body"))
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

  private func audioFlowPill(icon: String, title: String, color: Color, background: Color)
    -> some View
  {
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
      sectionTitle(appState.localized("system_info"))

      VStack(spacing: 0) {
        monitorInfoRow(
          icon: "clock", color: .blue, title: appState.localized("system_uptime"),
          value: formatUptimeLong(appState.systemMonitorService.systemUptime))
        Divider().padding(.leading, 42)
        monitorInfoRow(
          icon: "display", color: .cyan, title: appState.localized("connected_displays"),
          value: "\(appState.systemMonitorService.connectedDisplays)")
        Divider().padding(.leading, 42)
        monitorInfoRow(
          icon: "thermometer", color: .green, title: appState.localized("thermal_state"),
          value: thermalStateText(appState.systemMonitorService.thermalState), valueColor: .green)
        Divider().padding(.leading, 42)
        monitorInfoRow(
          icon: "battery.100",
          color: .green,
          title: appState.localized("battery"),
          value: batteryStatusText,
          valueColor: .green
        )
      }
    }
  }

  private var batteryStatusText: String {
    let chargingKey = appState.systemMonitorService.isCharging ? "charging" : "on_battery"
    return "\(appState.systemMonitorService.batteryLevel)% (\(appState.localized(chargingKey)))"
  }

  private var resourceUsageSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      sectionTitle(appState.localized("resource_usage"))

      VStack(spacing: 13) {
        resourceRow(
          icon: "cpu",
          title: appState.localized("cpu"),
          valueText: String(format: "%.1f%%", appState.systemMonitorService.cpuUsage),
          percent: appState.systemMonitorService.cpuUsage,
          color: .green
        )

        resourceRow(
          icon: "memorychip",
          title: appState.localized("memory"),
          valueText: capacityText(
            used: appState.systemMonitorService.memoryUsed,
            total: appState.systemMonitorService.memoryTotal, fractionDigits: 2),
          percent: percent(
            used: appState.systemMonitorService.memoryUsed,
            total: appState.systemMonitorService.memoryTotal),
          color: .orange
        )

        resourceRow(
          icon: "internaldrive",
          title: appState.localized("disk"),
          valueText: capacityText(
            used: appState.systemMonitorService.diskUsed,
            total: appState.systemMonitorService.diskTotal, fractionDigits: 0),
          percent: percent(
            used: appState.systemMonitorService.diskUsed,
            total: appState.systemMonitorService.diskTotal),
          color: .orange
        )
      }
    }
  }

  private var quickActionsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      sectionTitle(appState.localized("quick_actions"))

      HStack(spacing: 32) {
        quickAction(icon: "arrow.clockwise", label: appState.localized("refresh")) {
          appState.systemMonitorService.refresh()
        }
        quickAction(icon: "chart.bar", label: appState.localized("activity")) {
          NSWorkspace.shared.open(
            URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
        }
        quickAction(icon: "info.circle", label: appState.localized("system_info")) {
          NSWorkspace.shared.open(
            URL(fileURLWithPath: "/System/Applications/Utilities/System Information.app"))
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

  private func monitorInfoRow(
    icon: String, color: Color, title: String, value: String, valueColor: Color = .primary
  ) -> some View {
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

  private func resourceRow(
    icon: String, title: String, valueText: String, percent: Double, color: Color
  ) -> some View {
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
    case .nominal: return appState.localized("normal")
    case .fair: return appState.localized("fair")
    case .serious: return appState.localized("serious")
    case .critical: return appState.localized("critical")
    @unknown default: return appState.localized("unknown")
    }
  }

  private func percent(used: UInt64, total: UInt64) -> Double {
    guard total > 0 else { return 0 }
    return min(100, (Double(used) / Double(total)) * 100)
  }

  private func capacityText(used: UInt64, total: UInt64, fractionDigits: Int) -> String {
    guard total > 0 else { return appState.localized("unavailable") }
    let divisor = 1_073_741_824.0
    let usedGB = Double(used) / divisor
    let totalGB = Double(total) / divisor
    return String(format: "%.*f GB / %.*f GB", fractionDigits, usedGB, fractionDigits, totalGB)
  }

}

// MARK: - SettingsTabView

struct SettingsTabView: View {
  @EnvironmentObject var appState: AppState

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        generalSettings
        appearanceSettings
        aboutSection
      }
      .padding(.horizontal, 20)
      .padding(.top, 24)
      .padding(.bottom, 22)
    }
  }

  private var generalSettings: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(appState.localized("general"))
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.secondary)

      VStack(spacing: 0) {
        settingRow(
          icon: "arrow.right.circle",
          title: appState.localized("launch_at_login"),
          subtitle: appState.localized("launch_at_login_subtitle"),
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
          title: appState.localized("restore_last_config"),
          subtitle: appState.localized("restore_last_config_subtitle"),
          isOn: $appState.restoreLastConfig
        )
        Divider().padding(.leading, 46)

        settingRow(
          icon: "laptopcomputer.and.arrow.down",
          title: appState.localized("automatic_clamshell_virtual_display"),
          subtitle: appState.localized("automatic_clamshell_virtual_display_subtitle"),
          isOn: Binding(
            get: { appState.automaticClamshellVirtualDisplayEnabled },
            set: { appState.setAutomaticClamshellVirtualDisplayEnabled($0) }
          )
        )
        Divider().padding(.leading, 46)

        settingRow(
          icon: "keyboard",
          title: appState.localized("global_hotkey"),
          subtitle: appState.localized("global_hotkey_subtitle"),
          isOn: Binding(
            get: { appState.hotkeyEnabled },
            set: { appState.setHotkeyEnabled($0) }
          )
        )
        Divider().padding(.leading, 46)

        settingRow(
          icon: "bell",
          title: appState.localized("notifications"),
          subtitle: appState.localized("notifications_subtitle"),
          isOn: Binding(
            get: { appState.notificationsEnabled },
            set: { appState.setNotificationsEnabled($0) }
          )
        )
        Divider().padding(.leading, 46)

        settingRow(
          icon: "rectangle.dock",
          title: appState.localized("show_in_dock"),
          subtitle: appState.localized("show_in_dock_subtitle"),
          isOn: Binding(
            get: { appState.showInDock },
            set: { appState.setShowInDock($0) }
          )
        )
        Divider().padding(.leading, 46)

        settingRow(
          icon: "bolt.circle",
          title: appState.localized("auto_activate_launch"),
          subtitle: appState.localized("auto_activate_launch_subtitle"),
          isOn: $appState.autoActivateOnLaunch
        )
      }
    }
  }

  private var appearanceSettings: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(appState.localized("appearance"))
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.secondary)

      VStack(spacing: 0) {
        pickerRow(icon: "globe", title: appState.localized("language")) {
          Picker(
            "",
            selection: Binding(
              get: { appState.language },
              set: { appState.setLanguage($0) }
            )
          ) {
            ForEach(AppLanguage.allCases, id: \.self) { language in
              Text(appState.localized(language.titleKey))
                .tag(language)
            }
          }
          .labelsHidden()
          .frame(width: 145)
        }

        Text(appState.localized("language_restart_hint"))
          .font(.system(size: 11))
          .foregroundColor(.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.leading, 42)
          .padding(.bottom, 8)

        Divider().padding(.leading, 46)

        pickerRow(icon: "circle.lefthalf.filled", title: appState.localized("theme")) {
          Picker("", selection: $appState.theme) {
            Text(appState.localized("system")).tag(AppTheme.system)
            Text(appState.localized("light")).tag(AppTheme.light)
            Text(appState.localized("dark")).tag(AppTheme.dark)
          }
          .labelsHidden()
          .frame(width: 145)
        }
      }
    }
  }

  private var aboutSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(appState.localized("about"))
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.secondary)

      VStack(spacing: 0) {
        aboutRow(title: "CaffeinatePlus", value: Bundle.main.footerVersionText)
        Divider().padding(.leading, 46)
        aboutRow(
          title: appState.localized("license"), value: appState.licenseService.state.displayText,
          valueColor: .green)
        Divider().padding(.leading, 46)
        aboutRow(title: appState.localized("logs"), value: appState.localized("open")) {
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

  private func settingRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>)
    -> some View
  {
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

  private func pickerRow<Content: View>(
    icon: String, title: String, @ViewBuilder content: () -> Content
  ) -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 14))
        .foregroundColor(.secondary)
        .frame(width: 30)

      Text(title)
        .font(.system(size: 13))
        .foregroundColor(.primary)

      Spacer()

      content()
    }
    .frame(height: 44)
  }

  private func aboutRow(
    title: String, value: String, valueColor: Color = .secondary, action: (() -> Void)? = nil
  ) -> some View {
    Button(
      action: { action?() },
      label: {
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
    )
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

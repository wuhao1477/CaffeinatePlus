// VirtualDisplayService.swift
// Virtual display service backed by CoreGraphics private CGVirtualDisplay API.

import Combine
import Foundation

final class VirtualDisplayService: ObservableObject {

  // MARK: - Published Properties

  @Published private(set) var isActive = false
  @Published private(set) var currentConfig: DisplayConfig?
  @Published private(set) var isAPIAvailable: Bool
  @Published private(set) var displayID: UInt32 = 0

  var isDisplayCreated: Bool { isActive }

  // MARK: - Private Properties

  private let runtime: VirtualDisplayRuntime
  private var displayHandle: VirtualDisplayHandle?

  // MARK: - Initialization

  init(runtime: VirtualDisplayRuntime = ObjCCGVirtualDisplayRuntime()) {
    self.runtime = runtime
    isAPIAvailable = runtime.isAvailable
  }

  // MARK: - Public Methods

  func createDisplay(config: DisplayConfig) throws {
    try createDisplay(config: config, hiDPI: config.hiDPI)
  }

  func createDisplay(config: DisplayConfig, hiDPI: Bool) throws {
    guard #available(macOS 13.0, *) else {
      throw VirtualDisplayError.apiUnavailable
    }

    guard runtime.isAvailable else {
      isAPIAvailable = false
      Logger.shared.error("CGVirtualDisplay API is not available on this system.")
      throw VirtualDisplayError.apiUnavailable
    }

    if isActive {
      removeDisplay()
    }

    let spec = VirtualDisplaySpec(config: config, hiDPI: hiDPI)
    let handle = try runtime.createDisplay(spec: spec) { [weak self] in
      DispatchQueue.main.async {
        self?.handleTermination()
      }
    }

    displayHandle = handle
    displayID = handle.displayID
    currentConfig = DisplayConfig(
      width: config.width,
      height: config.height,
      hiDPI: hiDPI,
      refreshRate: config.refreshRate
    )
    isActive = true

    Logger.shared.info(
      "Virtual display created: \(spec.label), displayID=\(handle.displayID)"
    )
  }

  func removeDisplay() {
    guard isActive else { return }

    let removedDisplayID = displayID
    if let displayHandle {
      runtime.destroyDisplay(displayHandle)
    }

    displayHandle = nil
    displayID = 0
    isActive = false
    currentConfig = nil

    Logger.shared.info("Virtual display destroyed: displayID=\(removedDisplayID)")
  }

  // MARK: - Cleanup

  deinit {
    removeDisplay()
  }

  // MARK: - Private Methods

  private func handleTermination() {
    Logger.shared.info("Virtual display terminated by system")
    displayHandle = nil
    displayID = 0
    isActive = false
    currentConfig = nil
  }
}

// MARK: - Supporting Types

struct DisplayConfig: Codable, Equatable {
  var width: Int
  var height: Int
  var hiDPI: Bool
  var refreshRate: Double = 60.0

  enum CodingKeys: String, CodingKey {
    case width
    case height
    case hiDPI
    case refreshRate
  }

  static let presets: [DisplayConfig] = [
    DisplayConfig(width: 1920, height: 1080, hiDPI: false, refreshRate: 60.0),
    DisplayConfig(width: 2560, height: 1440, hiDPI: false, refreshRate: 60.0),
    DisplayConfig(width: 3840, height: 2160, hiDPI: false, refreshRate: 60.0),
    DisplayConfig(width: 1920, height: 1080, hiDPI: true, refreshRate: 60.0),
    DisplayConfig(width: 2560, height: 1440, hiDPI: true, refreshRate: 60.0),
  ]
}

enum VirtualDisplayError: LocalizedError, Equatable {
  case apiUnavailable
  case createFailed(String)
  case settingsApplyFailed

  var errorDescription: String? {
    switch self {
    case .apiUnavailable:
      return AppLocalization.localized("virtual_display_api_unavailable_error")
    case .createFailed(let reason):
      let format = AppLocalization.localized("virtual_display_create_failed_error")
      return String(format: format, reason)
    case .settingsApplyFailed:
      return AppLocalization.localized("virtual_display_apply_settings_failed_error")
    }
  }
}

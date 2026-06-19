// ClamshellDisplayConfiguration.swift
// Applies and restores display enablement for automatic clamshell headless mode.

import CoreGraphics
import Foundation

final class ClamshellDisplayConfiguration: ClamshellDisplayConfiguring {
  typealias DisplayEnabledFunction = @convention(c) (CGDisplayConfigRef?, CGDirectDisplayID, Int32) -> CGError

  private let displayEnabled: DisplayEnabledFunction?

  init() {
    displayEnabled = ClamshellDisplayConfiguration.resolveDisplayEnabledFunction()
  }

  init(displayEnabled: DisplayEnabledFunction?) {
    self.displayEnabled = displayEnabled
  }

  func captureDisplayConfiguration() -> ClamshellDisplaySnapshot {
    makeSnapshot()
  }

  func enterHeadlessMode(
    virtualDisplayID: UInt32,
    originalSnapshot: ClamshellDisplaySnapshot
  ) throws {
    guard virtualDisplayID != 0 else {
      throw CaffeinateError.configurationError("Virtual display ID is unavailable")
    }

    let builtinDisplays = originalSnapshot.displays.filter { CGDisplayIsBuiltin($0.id) != 0 }
    guard !builtinDisplays.isEmpty else {
      throw CaffeinateError.configurationError("No built-in display found for clamshell headless mode")
    }

    Logger.shared.info(
      "Entering clamshell headless mode: allDisplays=\(originalSnapshot.displayIDs), builtInDisplays=\(builtinDisplays.map(\.id)), virtualDisplayID=\(virtualDisplayID)"
    )

    try applyDisplayTransaction { config in
      try configureDisplayEnabled(config, virtualDisplayID, true)

      for display in builtinDisplays {
        try configureDisplayEnabled(config, display.id, false)
      }
    }

    Logger.shared.info("Built-in display disabled for clamshell headless mode")
  }

  func restoreDisplayConfiguration(_ snapshot: ClamshellDisplaySnapshot) {
    do {
      try applyDisplayTransaction { config in
        for display in snapshot.displays {
          try configureDisplayEnabled(config, display.id, true)
        }
      }
      Logger.shared.info("Display enablement restored after clamshell mode")
    } catch {
      Logger.shared.error("Failed to restore display enablement: \(error)")
      CGRestorePermanentDisplayConfiguration()
    }
  }

  private func makeSnapshot() -> ClamshellDisplaySnapshot {
    ClamshellDisplaySnapshot(
      displays: onlineDisplays().map { displayID in
        let bounds = CGDisplayBounds(displayID)
        return ClamshellDisplaySnapshot.Display(
          id: displayID,
          mode: CGDisplayCopyDisplayMode(displayID),
          originX: Int32(bounds.origin.x),
          originY: Int32(bounds.origin.y),
          mirrorsDisplayID: CGDisplayMirrorsDisplay(displayID),
          isMain: CGDisplayIsMain(displayID) != 0
        )
      }
    )
  }

  private func onlineDisplays() -> [UInt32] {
    var count: UInt32 = 0
    guard CGGetOnlineDisplayList(0, nil, &count) == .success, count > 0 else {
      return []
    }

    var displays = [UInt32](repeating: 0, count: Int(count))
    guard CGGetOnlineDisplayList(count, &displays, &count) == .success else {
      return []
    }

    return Array(displays.prefix(Int(count)))
  }

  private func applyDisplayTransaction(_ configure: (CGDisplayConfigRef?) throws -> Void) throws {
    var config: CGDisplayConfigRef?
    let beginError = CGBeginDisplayConfiguration(&config)
    guard beginError == .success else {
      throw CaffeinateError.configurationError("CGBeginDisplayConfiguration failed: \(beginError)")
    }

    do {
      try configure(config)
    } catch {
      CGCancelDisplayConfiguration(config)
      throw error
    }

    let completeError = CGCompleteDisplayConfiguration(config, .forSession)
    guard completeError == .success else {
      CGCancelDisplayConfiguration(config)
      throw CaffeinateError.configurationError("CGCompleteDisplayConfiguration failed: \(completeError)")
    }
  }

  private func configureDisplayEnabled(
    _ config: CGDisplayConfigRef?,
    _ displayID: CGDirectDisplayID,
    _ enabled: Bool
  ) throws {
    guard let displayEnabled else {
      throw CaffeinateError.configurationError("Display enable API is unavailable")
    }

    Logger.shared.info("Configuring display \(displayID) enabled=\(enabled)")
    let error = displayEnabled(config, displayID, enabled ? 1 : 0)
    guard error == .success else {
      throw CaffeinateError.configurationError(
        "Configure display enabled failed for \(displayID): \(error)"
      )
    }
  }

  private static func resolveDisplayEnabledFunction() -> DisplayEnabledFunction? {
    let frameworkPaths = [
      "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
      "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics",
    ]
    let symbolNames = ["SLSConfigureDisplayEnabled", "CGSConfigureDisplayEnabled"]

    for frameworkPath in frameworkPaths {
      guard let handle = dlopen(frameworkPath, RTLD_LAZY) else { continue }

      for symbolName in symbolNames {
        if let symbol = dlsym(handle, symbolName) {
          return unsafeBitCast(symbol, to: DisplayEnabledFunction.self)
        }
      }
    }

    return nil
  }
}

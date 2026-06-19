// ClamshellDisplayConfiguration.swift
// Tracks display state for automatic clamshell headless mode.

import CoreGraphics
import Foundation

final class ClamshellDisplayConfiguration: ClamshellDisplayConfiguring {
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

    Logger.shared.info(
      "Using system clamshell display handling: allDisplays=\(originalSnapshot.displayIDs), virtualDisplayID=\(virtualDisplayID)"
    )
  }

  func restoreDisplayConfiguration(_ snapshot: ClamshellDisplaySnapshot) {
    Logger.shared.info(
      "No manual display restore needed after clamshell mode: displays=\(snapshot.displayIDs)"
    )
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
}

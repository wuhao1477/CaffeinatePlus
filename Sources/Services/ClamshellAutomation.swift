// ClamshellAutomation.swift
// Coordinates lid close/open actions for headless clamshell mode.

import CoreGraphics
import Foundation

protocol ClamshellVirtualDisplayControlling: AnyObject {
  var isActive: Bool { get }
  var displayID: UInt32 { get }
  func createDisplay(config: DisplayConfig) throws
  func removeDisplay()
}

protocol ClamshellSleepControlling: AnyObject {
  var snapshot: ClamshellSleepSnapshot { get }
  func preventSleep() throws
  func restoreSleepState(_ snapshot: ClamshellSleepSnapshot)
}

protocol ClamshellDisplayConfiguring: AnyObject {
  func captureDisplayConfiguration() -> ClamshellDisplaySnapshot
  func enterHeadlessMode(
    virtualDisplayID: UInt32,
    originalSnapshot: ClamshellDisplaySnapshot
  ) throws
  func restoreDisplayConfiguration(_ snapshot: ClamshellDisplaySnapshot)
}

struct ClamshellSleepSnapshot: Equatable {
  let preventDisplaySleep: Bool
  let preventSystemSleep: Bool
  let preventScreenSaver: Bool
  let preventAutoLock: Bool
}

struct ClamshellDisplaySnapshot: Equatable {
  struct Display {
    let id: UInt32
    let mode: CGDisplayMode?
    let originX: Int32
    let originY: Int32
    let mirrorsDisplayID: UInt32
    let isMain: Bool
  }

  let displays: [Display]

  var displayIDs: [UInt32] {
    displays.map(\.id)
  }

  init(displays: [Display]) {
    self.displays = displays
  }

  init(displayIDs: [UInt32]) {
    displays = displayIDs.map {
      Display(id: $0, mode: nil, originX: 0, originY: 0, mirrorsDisplayID: 0, isMain: false)
    }
  }

  static func == (lhs: ClamshellDisplaySnapshot, rhs: ClamshellDisplaySnapshot) -> Bool {
    lhs.displayIDs == rhs.displayIDs
  }
}

final class ClamshellAutomation {
  private var session: ClamshellSession?

  func lidDidClose(
    config: DisplayConfig,
    wasAppActive: Bool,
    virtualDisplay: ClamshellVirtualDisplayControlling,
    sleep: ClamshellSleepControlling,
    displayConfiguration: ClamshellDisplayConfiguring
  ) throws -> Bool {
    guard session == nil else {
      return true
    }

    Logger.shared.info("Auto mode: lid closed, activating...")

    let sleepSnapshot = sleep.snapshot
    let displaySnapshot = displayConfiguration.captureDisplayConfiguration()
    let shouldRemoveVirtualDisplay = !virtualDisplay.isActive
    var createdVirtualDisplay = false

    do {
      try sleep.preventSleep()

      if !virtualDisplay.isActive {
        try virtualDisplay.createDisplay(config: config)
        createdVirtualDisplay = true
      }

      try displayConfiguration.enterHeadlessMode(
        virtualDisplayID: virtualDisplay.displayID,
        originalSnapshot: displaySnapshot
      )

      session = ClamshellSession(
        wasAppActive: wasAppActive,
        shouldRemoveVirtualDisplay: shouldRemoveVirtualDisplay,
        sleepSnapshot: sleepSnapshot,
        displaySnapshot: displaySnapshot
      )

      Logger.shared.info("Virtual display created. Sleep prevention enabled.")
      return true
    } catch {
      if createdVirtualDisplay {
        virtualDisplay.removeDisplay()
      }
      sleep.restoreSleepState(sleepSnapshot)
      throw error
    }

  }

  func lidDidOpen(
    virtualDisplay: ClamshellVirtualDisplayControlling,
    sleep: ClamshellSleepControlling,
    displayConfiguration: ClamshellDisplayConfiguring
  ) -> Bool? {
    Logger.shared.info("Auto mode: lid opened, deactivating...")

    guard let session else {
      return nil
    }

    displayConfiguration.restoreDisplayConfiguration(session.displaySnapshot)
    sleep.restoreSleepState(session.sleepSnapshot)

    if session.shouldRemoveVirtualDisplay {
      virtualDisplay.removeDisplay()
    }

    self.session = nil
    Logger.shared.info("Virtual display removed. Normal sleep behavior restored.")
    return session.wasAppActive
  }
}

private struct ClamshellSession {
  let wasAppActive: Bool
  let shouldRemoveVirtualDisplay: Bool
  let sleepSnapshot: ClamshellSleepSnapshot
  let displaySnapshot: ClamshellDisplaySnapshot
}

extension VirtualDisplayService: ClamshellVirtualDisplayControlling {}
extension SleepService: ClamshellSleepControlling {
  var snapshot: ClamshellSleepSnapshot {
    ClamshellSleepSnapshot(
      preventDisplaySleep: preventDisplaySleep,
      preventSystemSleep: preventSystemSleep,
      preventScreenSaver: preventScreenSaver,
      preventAutoLock: preventAutoLock
    )
  }

  func restoreSleepState(_ snapshot: ClamshellSleepSnapshot) {
    preventDisplaySleep = snapshot.preventDisplaySleep
    preventSystemSleep = snapshot.preventSystemSleep
    preventScreenSaver = snapshot.preventScreenSaver
    preventAutoLock = snapshot.preventAutoLock
  }
}

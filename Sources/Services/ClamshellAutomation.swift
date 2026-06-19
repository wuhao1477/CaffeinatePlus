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
  func preventSystemSleepForClamshell() throws
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
  private var preparedVirtualDisplayByAutomation = false
  private var preparedWasAppActive: Bool?

  func prepareForLidClose(
    config: DisplayConfig,
    virtualDisplay: ClamshellVirtualDisplayControlling,
    wasAppActive: Bool = false
  ) throws -> Bool {
    guard session == nil else { return false }
    guard !virtualDisplay.isActive else {
      preparedVirtualDisplayByAutomation = false
      preparedWasAppActive = nil
      return false
    }

    Logger.shared.info("Auto mode: preparing virtual display before lid close")
    try virtualDisplay.createDisplay(config: config)
    preparedVirtualDisplayByAutomation = true
    preparedWasAppActive = wasAppActive
    return true
  }

  func cancelPreparedVirtualDisplay(
    virtualDisplay: ClamshellVirtualDisplayControlling
  ) {
    guard preparedVirtualDisplayByAutomation else { return }
    virtualDisplay.removeDisplay()
    preparedVirtualDisplayByAutomation = false
    preparedWasAppActive = nil
    Logger.shared.info("Auto mode: prepared virtual display removed")
  }

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
    var createdVirtualDisplayForClose = preparedVirtualDisplayByAutomation

    do {
      if virtualDisplay.displayID == 0 {
        Logger.shared.info("Auto mode: creating virtual display after lid close")
        try virtualDisplay.createDisplay(config: config)
        createdVirtualDisplayForClose = true
      }

      try sleep.preventSystemSleepForClamshell()
      Logger.shared.info("Auto mode: system sleep prevention enabled before display reconfiguration")

      let displaySnapshot = displayConfiguration.captureDisplayConfiguration()
      Logger.shared.info(
        "Auto mode: captured displays \(displaySnapshot.displayIDs), virtualDisplayID=\(virtualDisplay.displayID)"
      )

      try displayConfiguration.enterHeadlessMode(
        virtualDisplayID: virtualDisplay.displayID,
        originalSnapshot: displaySnapshot
      )

      session = ClamshellSession(
        wasAppActive: preparedWasAppActive ?? wasAppActive,
        shouldRemoveVirtualDisplay: createdVirtualDisplayForClose,
        sleepSnapshot: sleepSnapshot,
        displaySnapshot: displaySnapshot
      )
      preparedVirtualDisplayByAutomation = false
      preparedWasAppActive = nil

      Logger.shared.info("Virtual display created. Sleep prevention enabled.")
      return true
    } catch {
      Logger.shared.error("Auto mode: lid close activation failed: \(error)")
      if createdVirtualDisplayForClose {
        virtualDisplay.removeDisplay()
      }
      preparedVirtualDisplayByAutomation = false
      preparedWasAppActive = nil
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

  func preventSystemSleepForClamshell() throws {
    preventSystemSleep = true
  }
}

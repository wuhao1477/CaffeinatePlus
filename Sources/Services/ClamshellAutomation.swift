// ClamshellAutomation.swift
// Coordinates lid close/open actions for headless clamshell mode.

import Foundation

protocol ClamshellVirtualDisplayControlling: AnyObject {
  var isActive: Bool { get }
  func createDisplay(config: DisplayConfig) throws
  func removeDisplay()
}

protocol ClamshellSleepControlling: AnyObject {
  func preventSleep() throws
  func allowSleep()
}

final class ClamshellAutomation {
  private var createdSession = false

  func lidDidClose(
    config: DisplayConfig,
    wasAppActive: Bool,
    virtualDisplay: ClamshellVirtualDisplayControlling,
    sleep: ClamshellSleepControlling
  ) throws -> Bool {
    Logger.shared.info("Auto mode: lid closed, activating...")

    if !virtualDisplay.isActive {
      try virtualDisplay.createDisplay(config: config)
      createdSession = !wasAppActive
    }

    try sleep.preventSleep()
    Logger.shared.info("Virtual display created. Sleep prevention enabled.")
    return true
  }

  func lidDidOpen(
    virtualDisplay: ClamshellVirtualDisplayControlling,
    sleep: ClamshellSleepControlling
  ) -> Bool? {
    Logger.shared.info("Auto mode: lid opened, deactivating...")

    guard createdSession else {
      return nil
    }

    sleep.allowSleep()
    virtualDisplay.removeDisplay()
    createdSession = false
    Logger.shared.info("Virtual display removed. Normal sleep behavior restored.")
    return false
  }
}

extension VirtualDisplayService: ClamshellVirtualDisplayControlling {}
extension SleepService: ClamshellSleepControlling {}

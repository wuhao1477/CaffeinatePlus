// ClamshellPowerManagement.swift
// Keeps clamshell sleep disabled while the app is available to react to lid changes.

import Foundation
import IOKit
import IOKit.pwr_mgt

private let kPMSetClamshellSleepStateSelector: UInt32 = 12

protocol ClamshellPowerManaging: AnyObject {
  func activateAutomaticClamshellProtection() throws
  func deactivateAutomaticClamshellProtection()
}

struct ClamshellPowerSnapshot: Equatable {
  let causesSleepBeforeDisable: Bool?

  var shouldRestoreClamshellSleep: Bool {
    causesSleepBeforeDisable != false
  }
}

final class ClamshellPowerManagement: ClamshellPowerManaging {
  private var automaticProtectionSnapshot: ClamshellPowerSnapshot?
  private var powerConnection: io_connect_t = 0

  deinit {
    deactivateAutomaticClamshellProtection()
  }

  func activateAutomaticClamshellProtection() throws {
    guard automaticProtectionSnapshot == nil else {
      Logger.shared.debug("Automatic clamshell sleep protection is already active")
      return
    }

    let snapshot = ClamshellPowerSnapshot(causesSleepBeforeDisable: readClamshellCausesSleep())
    let connection = try openPowerManagementConnection()

    do {
      try setClamshellSleepDisabled(true, connection: connection)
    } catch {
      IOServiceClose(connection)
      throw error
    }

    powerConnection = connection
    automaticProtectionSnapshot = snapshot
    Logger.shared.info(
      "Clamshell sleep disabled while CaffeinatePlus is monitoring lid state"
    )
  }

  func deactivateAutomaticClamshellProtection() {
    guard let snapshot = automaticProtectionSnapshot else {
      return
    }

    automaticProtectionSnapshot = nil

    guard snapshot.shouldRestoreClamshellSleep else {
      closePowerManagementConnection()
      Logger.shared.info("Clamshell sleep was disabled before CaffeinatePlus launched")
      return
    }

    do {
      try setClamshellSleepDisabled(false, connection: powerConnection)
      Logger.shared.info("Clamshell sleep state restored after CaffeinatePlus exited")
    } catch {
      Logger.shared.error("Failed to restore clamshell sleep state: \(error)")
    }
    closePowerManagementConnection()
  }

  private func openPowerManagementConnection() throws -> io_connect_t {
    let connection = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
    guard connection != 0 else {
      throw CaffeinateError.configurationError("IOPMrootDomain user client is unavailable")
    }
    return connection
  }

  private func closePowerManagementConnection() {
    guard powerConnection != 0 else { return }
    IOServiceClose(powerConnection)
    powerConnection = 0
  }

  private func setClamshellSleepDisabled(_ disabled: Bool, connection: io_connect_t) throws {
    var input = UInt64(disabled ? 1 : 0)
    var outputCount: UInt32 = 0
    let status = IOConnectCallScalarMethod(
      connection,
      kPMSetClamshellSleepStateSelector,
      &input,
      1,
      nil,
      &outputCount
    )

    guard status == kIOReturnSuccess else {
      throw CaffeinateError.configurationError(
        "Set clamshell sleep state failed: \(status)"
      )
    }
  }

  private func readClamshellCausesSleep() -> Bool? {
    let service = IOServiceGetMatchingService(
      kIOMainPortDefault,
      IOServiceMatching("IOPMrootDomain")
    )
    guard service != 0 else { return nil }
    defer { IOObjectRelease(service) }

    return IORegistryEntryCreateCFProperty(
      service,
      "AppleClamshellCausesSleep" as CFString,
      kCFAllocatorDefault,
      0
    )?.takeRetainedValue() as? Bool
  }
}

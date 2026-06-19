// VirtualDisplayRuntime.swift
// Objective-C runtime adapter for CoreGraphics private CGVirtualDisplay classes.

import CoreGraphics
import Foundation
import ObjectiveC

protocol VirtualDisplayRuntime {
  var isAvailable: Bool { get }

  func createDisplay(
    spec: VirtualDisplaySpec,
    terminationHandler: @escaping () -> Void
  ) throws -> VirtualDisplayHandle

  func destroyDisplay(_ handle: VirtualDisplayHandle)
}

struct VirtualDisplaySpec: Equatable {
  static let sizeInMillimeters = CGSize(width: 576.0, height: 336.0)
  static let name = "Caffeinate+ Virtual Display"
  static let serialNumber: UInt32 = 1
  static let productID: UInt32 = 0xCAFE
  static let vendorID: UInt32 = 0xBEEF

  let width: Int
  let height: Int
  let refreshRate: Double
  let hiDPI: Bool

  init(width: Int, height: Int, refreshRate: Double, hiDPI: Bool) {
    self.width = width
    self.height = height
    self.refreshRate = refreshRate
    self.hiDPI = hiDPI
  }

  init(config: DisplayConfig, hiDPI: Bool) {
    self.init(
      width: config.width,
      height: config.height,
      refreshRate: config.refreshRate,
      hiDPI: hiDPI
    )
  }

  var label: String {
    let dpiText = hiDPI ? "HiDPI" : "Standard"
    return "\(width)×\(height) @ \(Int(refreshRate))Hz (\(dpiText))"
  }
}

struct VirtualDisplayHandle {
  let displayID: UInt32
  let displayObject: AnyObject?
  let terminationHandlerObject: AnyObject?
}

final class ObjCCGVirtualDisplayRuntime: VirtualDisplayRuntime {
  static let requiredClassNames = [
    "CGVirtualDisplay",
    "CGVirtualDisplayDescriptor",
    "CGVirtualDisplayMode",
    "CGVirtualDisplaySettings",
  ]

  static let requiredSelectorNames = [
    "alloc",
    "init",
    "initWithWidth:height:refreshRate:",
    "setDispatchQueue:",
    "setName:",
    "setMaxPixelsWide:",
    "setMaxPixelsHigh:",
    "setSizeInMillimeters:",
    "setSerialNum:",
    "setProductID:",
    "setVendorID:",
    "setTerminationHandler:",
    "initWithDescriptor:",
    "setHiDPI:",
    "setModes:",
    "applySettings:",
    "displayID",
  ]

  private enum ClassName {
    static let display = "CGVirtualDisplay"
    static let descriptor = "CGVirtualDisplayDescriptor"
    static let mode = "CGVirtualDisplayMode"
    static let settings = "CGVirtualDisplaySettings"
  }

  private enum SelectorName {
    static let alloc = "alloc"
    static let initialize = "init"
    static let initMode = "initWithWidth:height:refreshRate:"
    static let setDispatchQueue = "setDispatchQueue:"
    static let setName = "setName:"
    static let setMaxPixelsWide = "setMaxPixelsWide:"
    static let setMaxPixelsHigh = "setMaxPixelsHigh:"
    static let setSizeInMillimeters = "setSizeInMillimeters:"
    static let setSerialNum = "setSerialNum:"
    static let setProductID = "setProductID:"
    static let setVendorID = "setVendorID:"
    static let setTerminationHandler = "setTerminationHandler:"
    static let initDisplay = "initWithDescriptor:"
    static let setHiDPI = "setHiDPI:"
    static let setModes = "setModes:"
    static let applySettings = "applySettings:"
    static let displayID = "displayID"
  }

  private let messaging = ObjCMessaging()

  var isAvailable: Bool {
    Self.requiredClassNames.allSatisfy { NSClassFromString($0) != nil }
  }

  func createDisplay(
    spec: VirtualDisplaySpec,
    terminationHandler: @escaping () -> Void
  ) throws -> VirtualDisplayHandle {
    guard isAvailable else {
      throw VirtualDisplayError.apiUnavailable
    }

    let mode = try makeMode(spec: spec)
    let descriptor = try makeDescriptor(spec: spec, terminationHandler: terminationHandler)
    let display = try makeDisplay(descriptor: descriptor.object)
    let settings = try makeSettings(mode: mode, hiDPI: spec.hiDPI)

    guard messaging.sendBool(
      to: display,
      selector: SelectorName.applySettings,
      object: settings
    ) else {
      throw VirtualDisplayError.settingsApplyFailed
    }

    return VirtualDisplayHandle(
      displayID: messaging.sendUInt32(to: display, selector: SelectorName.displayID),
      displayObject: display,
      terminationHandlerObject: descriptor.terminationHandlerObject
    )
  }

  func destroyDisplay(_ handle: VirtualDisplayHandle) {
    _ = handle.displayObject
    _ = handle.terminationHandlerObject
  }

  private func makeMode(spec: VirtualDisplaySpec) throws -> AnyObject {
    guard let modeClass = NSClassFromString(ClassName.mode) else {
      throw VirtualDisplayError.apiUnavailable
    }

    let allocated = messaging.alloc(modeClass)
    return try messaging.sendObject(
      to: allocated,
      selector: SelectorName.initMode,
      int: spec.width,
      secondInt: spec.height,
      double: spec.refreshRate
    )
  }

  private func makeDescriptor(
    spec: VirtualDisplaySpec,
    terminationHandler: @escaping () -> Void
  ) throws -> (object: AnyObject, terminationHandlerObject: AnyObject) {
    guard let descriptorClass = NSClassFromString(ClassName.descriptor) else {
      throw VirtualDisplayError.apiUnavailable
    }

    let descriptor = try messaging.sendObject(
      to: messaging.alloc(descriptorClass),
      selector: SelectorName.initialize
    )
    let block: @convention(block) (Any?, Any?) -> Void = { _, _ in
      terminationHandler()
    }
    let blockObject = block as AnyObject

    messaging.sendVoid(to: descriptor, selector: SelectorName.setDispatchQueue, object: DispatchQueue.main as AnyObject)
    messaging.sendVoid(to: descriptor, selector: SelectorName.setName, object: VirtualDisplaySpec.name as NSString)
    messaging.sendVoid(to: descriptor, selector: SelectorName.setMaxPixelsWide, int: spec.width)
    messaging.sendVoid(to: descriptor, selector: SelectorName.setMaxPixelsHigh, int: spec.height)
    messaging.sendVoid(
      to: descriptor,
      selector: SelectorName.setSizeInMillimeters,
      double: VirtualDisplaySpec.sizeInMillimeters.width,
      secondDouble: VirtualDisplaySpec.sizeInMillimeters.height
    )
    messaging.sendVoid(to: descriptor, selector: SelectorName.setSerialNum, uint32: VirtualDisplaySpec.serialNumber)
    messaging.sendVoid(to: descriptor, selector: SelectorName.setProductID, uint32: VirtualDisplaySpec.productID)
    messaging.sendVoid(to: descriptor, selector: SelectorName.setVendorID, uint32: VirtualDisplaySpec.vendorID)
    messaging.sendVoid(to: descriptor, selector: SelectorName.setTerminationHandler, object: blockObject)

    return (descriptor, blockObject)
  }

  private func makeDisplay(descriptor: AnyObject) throws -> AnyObject {
    guard let displayClass = NSClassFromString(ClassName.display) else {
      throw VirtualDisplayError.apiUnavailable
    }

    return try messaging.sendObject(
      to: messaging.alloc(displayClass),
      selector: SelectorName.initDisplay,
      object: descriptor
    )
  }

  private func makeSettings(mode: AnyObject, hiDPI: Bool) throws -> AnyObject {
    guard let settingsClass = NSClassFromString(ClassName.settings) else {
      throw VirtualDisplayError.apiUnavailable
    }

    let settings = try messaging.sendObject(
      to: messaging.alloc(settingsClass),
      selector: SelectorName.initialize
    )
    messaging.sendVoid(to: settings, selector: SelectorName.setHiDPI, bool: hiDPI)
    messaging.sendVoid(to: settings, selector: SelectorName.setModes, object: [mode] as NSArray)
    return settings
  }
}

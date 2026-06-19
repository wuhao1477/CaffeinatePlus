// ObjCMessaging.swift
// Typed wrappers around objc_msgSend for the CGVirtualDisplay runtime adapter.

import Foundation
import ObjectiveC

final class ObjCMessaging {
  private typealias ObjectReturn = @convention(c) (AnyObject, Selector) -> Unmanaged<AnyObject>?
  private typealias ObjectObjectReturn =
    @convention(c) (AnyObject, Selector, AnyObject) -> Unmanaged<AnyObject>?
  private typealias ObjectIntIntDoubleReturn =
    @convention(c) (AnyObject, Selector, Int, Int, Double) -> Unmanaged<AnyObject>?
  private typealias VoidObject = @convention(c) (AnyObject, Selector, AnyObject) -> Void
  private typealias VoidInt = @convention(c) (AnyObject, Selector, Int) -> Void
  private typealias VoidUInt32 = @convention(c) (AnyObject, Selector, UInt32) -> Void
  private typealias VoidBool = @convention(c) (AnyObject, Selector, Bool) -> Void
  private typealias VoidDoubleDouble = @convention(c) (AnyObject, Selector, Double, Double) -> Void
  private typealias BoolObject = @convention(c) (AnyObject, Selector, AnyObject) -> Bool
  private typealias UInt32Return = @convention(c) (AnyObject, Selector) -> UInt32

  private let msgSend: UnsafeMutableRawPointer

  init() {
    guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "objc_msgSend") else {
      fatalError("objc_msgSend is unavailable")
    }
    msgSend = symbol
  }

  func alloc(_ cls: AnyClass) -> AnyObject {
    let selector = NSSelectorFromString("alloc")
    let function = unsafeBitCast(msgSend, to: ObjectReturn.self)
    guard let result = function(cls as AnyObject, selector)?.takeUnretainedValue() else {
      fatalError("Unable to allocate Objective-C class \(cls)")
    }
    return result
  }

  func sendObject(to target: AnyObject, selector selectorName: String) throws -> AnyObject {
    guard let result = sendOptionalObject(to: target, selector: selectorName) else {
      throw VirtualDisplayError.createFailed("Objective-C selector failed: \(selectorName)")
    }
    return result
  }

  func sendObject(
    to target: AnyObject,
    selector selectorName: String,
    object: AnyObject
  ) throws -> AnyObject {
    let selector = NSSelectorFromString(selectorName)
    let function = unsafeBitCast(msgSend, to: ObjectObjectReturn.self)
    guard let result = function(target, selector, object)?.takeRetainedValue() else {
      throw VirtualDisplayError.createFailed("Objective-C selector failed: \(selectorName)")
    }
    return result
  }

  func sendObject(
    to target: AnyObject,
    selector selectorName: String,
    int: Int,
    secondInt: Int,
    double: Double
  ) throws -> AnyObject {
    let selector = NSSelectorFromString(selectorName)
    let function = unsafeBitCast(msgSend, to: ObjectIntIntDoubleReturn.self)
    guard let result = function(target, selector, int, secondInt, double)?.takeRetainedValue() else {
      throw VirtualDisplayError.createFailed("Objective-C selector failed: \(selectorName)")
    }
    return result
  }

  func sendVoid(to target: AnyObject, selector selectorName: String, object: AnyObject) {
    let selector = NSSelectorFromString(selectorName)
    let function = unsafeBitCast(msgSend, to: VoidObject.self)
    function(target, selector, object)
  }

  func sendVoid(to target: AnyObject, selector selectorName: String, int: Int) {
    let selector = NSSelectorFromString(selectorName)
    let function = unsafeBitCast(msgSend, to: VoidInt.self)
    function(target, selector, int)
  }

  func sendVoid(to target: AnyObject, selector selectorName: String, uint32: UInt32) {
    let selector = NSSelectorFromString(selectorName)
    let function = unsafeBitCast(msgSend, to: VoidUInt32.self)
    function(target, selector, uint32)
  }

  func sendVoid(to target: AnyObject, selector selectorName: String, bool: Bool) {
    let selector = NSSelectorFromString(selectorName)
    let function = unsafeBitCast(msgSend, to: VoidBool.self)
    function(target, selector, bool)
  }

  func sendVoid(
    to target: AnyObject,
    selector selectorName: String,
    double: Double,
    secondDouble: Double
  ) {
    let selector = NSSelectorFromString(selectorName)
    let function = unsafeBitCast(msgSend, to: VoidDoubleDouble.self)
    function(target, selector, double, secondDouble)
  }

  func sendBool(to target: AnyObject, selector selectorName: String, object: AnyObject) -> Bool {
    let selector = NSSelectorFromString(selectorName)
    let function = unsafeBitCast(msgSend, to: BoolObject.self)
    return function(target, selector, object)
  }

  func sendUInt32(to target: AnyObject, selector selectorName: String) -> UInt32 {
    let selector = NSSelectorFromString(selectorName)
    let function = unsafeBitCast(msgSend, to: UInt32Return.self)
    return function(target, selector)
  }

  private func sendOptionalObject(to target: AnyObject, selector selectorName: String) -> AnyObject? {
    let selector = NSSelectorFromString(selectorName)
    let function = unsafeBitCast(msgSend, to: ObjectReturn.self)
    return function(target, selector)?.takeRetainedValue()
  }
}

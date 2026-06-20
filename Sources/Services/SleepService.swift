// SleepServiceComplete.swift
// 完整版防睡眠服务
// 添加细粒度控制（对齐原始应用）

import Foundation
import IOKit.pwr_mgt

class SleepService: ObservableObject {

  // MARK: - Published Properties（细粒度控制）

  @Published var preventDisplaySleep: Bool = false {
    didSet { updateDisplaySleepAssertion() }
  }

  @Published var preventSystemSleep: Bool = false {
    didSet { updateSystemSleepAssertion() }
  }

  @Published var preventScreenSaver: Bool = false {
    didSet { updateUserActivitySimulation() }
  }

  @Published var preventAutoLock: Bool = false {
    didSet { updateUserActivitySimulation() }
  }

  // MARK: - Computed Properties

  var isPreventingAnything: Bool {
    preventDisplaySleep || preventSystemSleep || preventScreenSaver || preventAutoLock
  }

  // MARK: - Private Properties

  private var displayAssertionID: IOPMAssertionID = 0
  private var systemAssertionID: IOPMAssertionID = 0
  private var userActivityTimer: Timer?
  private let reason: String = "CaffeinatePlus Active"

  // MARK: - Constants

  private let userActivityInterval: TimeInterval = 30.0  // 30秒间隔

  // MARK: - Initialization

  init() {
    // 初始化时不自动激活
  }

  deinit {
    allowSleep()
  }

  // MARK: - Public Methods

  /// 开始防睡眠（一次性启用所有）
  func preventSleep() throws {
    preventDisplaySleep = true
    preventSystemSleep = true
    preventScreenSaver = true
    preventAutoLock = true

    Logger.shared.info("CaffeinatePlus Activated (all modes)")
  }

  /// 停止防睡眠（一次性禁用所有）
  func allowSleep() {
    preventDisplaySleep = false
    preventSystemSleep = false
    preventScreenSaver = false
    preventAutoLock = false

    Logger.shared.info("CaffeinatePlus Deactivated")
  }

  // MARK: - Private Update Methods

  /// 更新显示器睡眠断言
  private func updateDisplaySleepAssertion() {
    if preventDisplaySleep {
      createDisplaySleepAssertion()
    } else {
      releaseDisplaySleepAssertion()
    }
  }

  /// 更新系统睡眠断言
  private func updateSystemSleepAssertion() {
    if preventSystemSleep {
      createSystemSleepAssertion()
    } else {
      releaseSystemSleepAssertion()
    }
  }

  /// 更新用户活动模拟
  private func updateUserActivitySimulation() {
    if preventScreenSaver || preventAutoLock {
      startUserActivitySimulation()
    } else {
      stopUserActivitySimulation()
    }
  }

  // MARK: - Display Sleep Assertion

  private func createDisplaySleepAssertion() {
    guard displayAssertionID == 0 else { return }

    let assertionName = reason as CFString
    let assertionType = kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString

    let status = IOPMAssertionCreateWithName(
      assertionType,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      assertionName,
      &displayAssertionID
    )

    if status == kIOReturnSuccess {
      Logger.shared.info("Display sleep assertion created")
    } else {
      Logger.shared.error("Display sleep assertion failed: \(status)")
    }
  }

  private func releaseDisplaySleepAssertion() {
    guard displayAssertionID != 0 else { return }

    IOPMAssertionRelease(displayAssertionID)
    displayAssertionID = 0
    Logger.shared.info("Display sleep assertion released")
  }

  // MARK: - System Sleep Assertion

  private func createSystemSleepAssertion() {
    guard systemAssertionID == 0 else { return }

    let assertionName = reason as CFString
    let assertionType = kIOPMAssertionTypePreventSystemSleep as CFString

    let status = IOPMAssertionCreateWithName(
      assertionType,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      assertionName,
      &systemAssertionID
    )

    if status == kIOReturnSuccess {
      Logger.shared.info("System sleep assertion created")
    } else {
      Logger.shared.error("System sleep assertion failed: \(status)")
    }
  }

  private func releaseSystemSleepAssertion() {
    guard systemAssertionID != 0 else { return }

    IOPMAssertionRelease(systemAssertionID)
    systemAssertionID = 0
    Logger.shared.info("System sleep assertion released")
  }

  // MARK: - User Activity Simulation

  /// 启动用户活动模拟（防止屏保/锁屏）
  private func startUserActivitySimulation() {
    guard userActivityTimer == nil else { return }

    Logger.shared.info("User activity simulation started (30s interval)")

    userActivityTimer = Timer.scheduledTimer(
      withTimeInterval: userActivityInterval,
      repeats: true
    ) { [weak self] _ in
      self?.declareUserActivity()
    }

    // 立即触发一次
    declareUserActivity()
  }

  /// 停止用户活动模拟
  private func stopUserActivitySimulation() {
    userActivityTimer?.invalidate()
    userActivityTimer = nil
    Logger.shared.info("User activity simulation stopped")
  }

  /// 声明用户活动
  private func declareUserActivity() {
    var assertionID: IOPMAssertionID = 0

    // 声明本地用户活动
    let status = IOPMAssertionDeclareUserActivity(
      reason as CFString,
      kIOPMUserActiveLocal,
      &assertionID
    )

    if status == kIOReturnSuccess {
      // 立即释放（只需要触发活动事件）
      IOPMAssertionRelease(assertionID)
    } else {
      Logger.shared.error("User activity declaration failed: \(status)")
    }
  }
}

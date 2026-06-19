// ClamshellMonitor.swift
// 合盖状态监听服务
// 基于 IOKit IOPMrootDomain 通知

import Foundation
import IOKit
import IOKit.pwr_mgt

struct ClamshellStateChange: Equatable {
  let stateBits: UInt
  let isClosed: Bool
  let causesSleep: Bool
}

enum ClamshellPowerMessage {
  static let stateChangeType: UInt32 = 0xE003_4100

  static func parse(rawArgument: UInt) -> ClamshellStateChange {
    ClamshellStateChange(
      stateBits: rawArgument,
      isClosed: (rawArgument & UInt(kClamshellStateBit)) != 0,
      causesSleep: (rawArgument & UInt(kClamshellSleepBit)) != 0
    )
  }
}

class ClamshellMonitor: ObservableObject {

  // MARK: - Published Properties

  @Published private(set) var isClamshellClosed: Bool = false

  // MARK: - Private Properties

  private var rootDomainService: io_service_t = 0
  private var notificationPort: IONotificationPortRef?
  private var notifier: io_object_t = 0

  // MARK: - Initialization

  init() {
    startMonitoring()
  }

  deinit {
    stopMonitoring()
  }

  // MARK: - Public Methods

  /// 开始监听
  private func startMonitoring() {
    // 1. 获取 IOPMrootDomain 服务
    rootDomainService = IOServiceGetMatchingService(
      kIOMainPortDefault,
      IOServiceMatching("IOPMrootDomain")
    )

    guard rootDomainService != 0 else {
      Logger.shared.error("Failed to get IOPMrootDomain service")
      return
    }

    // 2. 创建通知端口
    notificationPort = IONotificationPortCreate(kIOMainPortDefault)
    guard let port = notificationPort else {
      Logger.shared.error("Failed to create IONotificationPort")
      IOObjectRelease(rootDomainService)
      return
    }

    // 3. 添加通知到 RunLoop
    IONotificationPortSetDispatchQueue(
      port,
      DispatchQueue.main
    )

    // 4. 注册合盖状态变更通知
    let context = Unmanaged.passUnretained(self).toOpaque()

    let status = IOServiceAddInterestNotification(
      port,
      rootDomainService,
      kIOGeneralInterest,
      clamshellCallback,
      context,
      &notifier
    )

    guard status == kIOReturnSuccess else {
      Logger.shared.error("Failed to register clamshell interest notification: \(status)")
      stopMonitoring()
      return
    }

    // 5. 初始状态检查
    refreshClamshellState()

    Logger.shared.info("Clamshell monitoring started")
  }

  /// 停止监听
  private func stopMonitoring() {
    if notifier != 0 {
      IOObjectRelease(notifier)
      notifier = 0
    }

    if let port = notificationPort {
      IONotificationPortDestroy(port)
      notificationPort = nil
    }

    if rootDomainService != 0 {
      IOObjectRelease(rootDomainService)
      rootDomainService = 0
    }
  }

  /// 从 IOKit 属性刷新合盖状态
  fileprivate func refreshClamshellState() {
    guard rootDomainService != 0 else { return }

    // 读取 AppleClamshellState 属性
    if let clamshellState = IORegistryEntryCreateCFProperty(
      rootDomainService,
      "AppleClamshellState" as CFString,
      kCFAllocatorDefault,
      0
    )?.takeRetainedValue() as? Bool {
      DispatchQueue.main.async {
        self.updateClamshellState(isClosed: clamshellState, source: "registry")
      }
    }
  }

  /// 使用 IOPMrootDomain 消息参数更新合盖状态
  fileprivate func updateClamshellState(isClosed: Bool, source: String) {
    guard isClamshellClosed != isClosed else {
      Logger.shared.debug("Clamshell state unchanged from \(source): \(isClosed ? "closed" : "open")")
      return
    }

    isClamshellClosed = isClosed
    Logger.shared.info("Clamshell state changed from \(source): \(isClosed ? "closed" : "open")")
  }
}

// MARK: - C Callback

/// IOKit 通知回调（C 函数）
private func clamshellCallback(
  refcon: UnsafeMutableRawPointer?,
  service: io_service_t,
  messageType: UInt32,
  messageArgument: UnsafeMutableRawPointer?
) {
  guard let refcon = refcon else { return }

  let monitor = Unmanaged<ClamshellMonitor>.fromOpaque(refcon).takeUnretainedValue()

  guard messageType == ClamshellPowerMessage.stateChangeType else {
    return
  }

  guard let messageArgument else {
    Logger.shared.warning("Clamshell message received without argument; refreshing registry state")
    monitor.refreshClamshellState()
    return
  }

  let change = ClamshellPowerMessage.parse(rawArgument: UInt(bitPattern: messageArgument))
  Logger.shared.info(
    "Clamshell message received: type=0x\(String(messageType, radix: 16)), bits=0x\(String(change.stateBits, radix: 16)), closed=\(change.isClosed), causesSleep=\(change.causesSleep)"
  )
  monitor.updateClamshellState(isClosed: change.isClosed, source: "message")
}

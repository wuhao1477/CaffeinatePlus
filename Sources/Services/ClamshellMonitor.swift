// ClamshellMonitor.swift
// 合盖状态监听服务
// 基于 IOKit IOPMrootDomain 通知

import Foundation
import IOKit
import IOKit.pwr_mgt

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
        updateClamshellState()

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

    /// 更新合盖状态
    fileprivate func updateClamshellState() {
        guard rootDomainService != 0 else { return }

        // 读取 AppleClamshellState 属性
        if let clamshellState = IORegistryEntryCreateCFProperty(
            rootDomainService,
            "AppleClamshellState" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Bool {
            DispatchQueue.main.async {
                self.isClamshellClosed = clamshellState
                Logger.shared.debug("Clamshell state: \(clamshellState ? "closed" : "open")")
            }
        }
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

    // kIOMessageClamshellStateChange = 0xE0000200
    if messageType == 0xE0000200 {
        monitor.updateClamshellState()
    }
}

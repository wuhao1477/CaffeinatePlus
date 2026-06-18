// SystemMonitorServiceFixed.swift
// 修复版系统监控服务
// 修复 CPU 使用率计算（使用差值而非累计值）

import Foundation
import IOKit.ps
import AppKit  // 添加 AppKit 以访问 NSScreen

class SystemMonitorService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var cpuUsage: Double = 0.0
    @Published private(set) var memoryUsed: UInt64 = 0
    @Published private(set) var memoryTotal: UInt64 = 0
    @Published private(set) var diskUsed: UInt64 = 0
    @Published private(set) var diskTotal: UInt64 = 0
    @Published private(set) var batteryLevel: Int = 0
    @Published private(set) var isCharging: Bool = false
    @Published private(set) var systemUptime: TimeInterval = 0
    @Published private(set) var connectedDisplays: Int = 0
    @Published private(set) var thermalState: ProcessInfo.ThermalState = .nominal

    // MARK: - Private Properties

    private var refreshTimer: DispatchSourceTimer?
    private var lastCPUTicks: [UInt64] = []  // 存储上次的 CPU 计数

    // MARK: - Constants

    private let REFRESH_INTERVAL: TimeInterval = 1.0  // 1秒刷新

    // MARK: - Initialization

    init() {
        setupTimer()
        refresh()
    }

    deinit {
        refreshTimer?.cancel()
    }

    // MARK: - Private Methods

    /// 设置定时器
    private func setupTimer() {
        refreshTimer = DispatchSource.makeTimerSource(queue: .main)
        refreshTimer?.schedule(
            deadline: .now(),
            repeating: REFRESH_INTERVAL,
            leeway: .milliseconds(100)
        )
        refreshTimer?.setEventHandler { [weak self] in
            self?.refresh()
        }
        refreshTimer?.resume()
    }

    /// 刷新所有监控数据
    func refresh() {
        refreshCPUUsage()
        refreshMemoryUsage()
        refreshDiskUsage()
        refreshBatteryInfo()

        // 简单属性
        systemUptime = ProcessInfo.processInfo.systemUptime
        connectedDisplays = NSScreen.screens.count
        thermalState = ProcessInfo.processInfo.thermalState
    }

    /// 刷新 CPU 使用率（修复版 - 使用差值计算）
    private func refreshCPUUsage() {
        var cpuInfo: processor_info_array_t?
        var numCPUInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCPUInfo
        )

        guard result == KERN_SUCCESS,
              let info = cpuInfo else {
            return
        }

        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: info),
                vm_size_t(Int(numCPUInfo) * MemoryLayout<integer_t>.stride)
            )
        }

        // 收集当前的 CPU ticks
        var currentTicks: [UInt64] = []
        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            let user = UInt64(info[offset + Int(CPU_STATE_USER)])
            let system = UInt64(info[offset + Int(CPU_STATE_SYSTEM)])
            let idle = UInt64(info[offset + Int(CPU_STATE_IDLE)])
            let nice = UInt64(info[offset + Int(CPU_STATE_NICE)])

            currentTicks.append(contentsOf: [user, system, idle, nice])
        }

        // 如果有上次的数据，计算差值
        if !lastCPUTicks.isEmpty && lastCPUTicks.count == currentTicks.count {
            var totalUsage: Double = 0
            let coresCount = Int(numCPUs)

            for core in 0..<coresCount {
                let baseIndex = core * 4

                let userDelta = Double(currentTicks[baseIndex] - lastCPUTicks[baseIndex])
                let systemDelta = Double(currentTicks[baseIndex + 1] - lastCPUTicks[baseIndex + 1])
                let idleDelta = Double(currentTicks[baseIndex + 2] - lastCPUTicks[baseIndex + 2])
                let niceDelta = Double(currentTicks[baseIndex + 3] - lastCPUTicks[baseIndex + 3])

                let total = userDelta + systemDelta + idleDelta + niceDelta

                if total > 0 {
                    let coreUsage = (userDelta + systemDelta + niceDelta) / total
                    totalUsage += coreUsage
                }
            }

            cpuUsage = (totalUsage / Double(coresCount)) * 100.0
        }

        // 保存当前 ticks 供下次使用
        lastCPUTicks = currentTicks
    }

    /// 刷新内存使用情况
    private func refreshMemoryUsage() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride
        )

        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(
                to: integer_t.self,
                capacity: Int(count)
            ) {
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    $0,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else { return }

        let pageSize = UInt64(vm_kernel_page_size)

        // 计算使用的内存（活动 + 有线）
        let used = (UInt64(stats.active_count) +
                    UInt64(stats.wire_count)) * pageSize

        let total = ProcessInfo.processInfo.physicalMemory

        memoryUsed = used
        memoryTotal = total
    }

    /// 刷新磁盘使用情况
    private func refreshDiskUsage() {
        do {
            let homeURL = FileManager.default.homeDirectoryForCurrentUser
            let values = try homeURL.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityKey
            ])

            if let total = values.volumeTotalCapacity,
               let available = values.volumeAvailableCapacity {
                diskTotal = UInt64(total)
                diskUsed = UInt64(total - available)
            }
        } catch {
            Logger.shared.error("Failed to get disk info: \(error)")
        }
    }

    /// 刷新电池信息
    private func refreshBatteryInfo() {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return
        }

        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                // 电量百分比
                if let capacity = info[kIOPSCurrentCapacityKey] as? Int {
                    batteryLevel = capacity
                }

                // 充电状态
                if let charging = info[kIOPSIsChargingKey] as? Bool {
                    isCharging = charging
                } else if let powerSource = info[kIOPSPowerSourceStateKey] as? String {
                    isCharging = (powerSource == kIOPSACPowerValue)
                }
            }
        }
    }
}

// AudioService.swift
// 音频路由服务
// 基于 CoreAudio 聚合设备实现

import Foundation
import CoreAudio
import AudioToolbox

class AudioService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var isRouting: Bool = false
    @Published private(set) var isDriverInstalled: Bool = false

    // MARK: - Private Properties

    private var aggregateDeviceID: AudioDeviceID = 0
    private var originalOutputDeviceID: AudioDeviceID = 0

    // MARK: - Constants

    private let BLACKHOLE_DRIVER_NAME = "BlackHole"
    private let AGGREGATE_DEVICE_NAME = "Caffeinate+ Audio"
    private let DEVICE_SWITCH_DELAY_MS: UInt32 = 500_000  // 500ms

    // MARK: - Initialization

    init() {
        checkDriverInstallation()
    }

    // MARK: - Public Methods

    /// 开始音频路由
    func startRouting() throws {
        guard !isRouting else { return }

        // 1. 检查 BlackHole 驱动
        guard isDriverInstalled else {
            let error = "Cannot start routing: BlackHole not installed"
            Logger.shared.error(error)
            throw AudioServiceError.driverNotInstalled
        }

        // 2. 保存原始输出设备
        originalOutputDeviceID = try getDefaultOutputDevice()

        // 3. 查找 BlackHole 设备
        let blackHoleID = try findBlackHoleDevice()

        // 4. 创建聚合设备（扬声器 + BlackHole）
        aggregateDeviceID = try createAggregateDevice(
            outputDeviceID: originalOutputDeviceID,
            virtualDeviceID: blackHoleID
        )

        // 5. 设置为默认输出设备
        try setDefaultOutputDevice(aggregateDeviceID)

        isRouting = true
        Logger.shared.info("Audio routing started: aggregate device \(aggregateDeviceID)")
    }

    /// 停止音频路由
    func stopRouting() {
        guard isRouting else { return }

        // 1. 恢复原始输出设备
        try? setDefaultOutputDevice(originalOutputDeviceID)

        // 2. 等待设备切换完成
        usleep(DEVICE_SWITCH_DELAY_MS)

        // 3. 销毁聚合设备
        if aggregateDeviceID != 0 {
            destroyAggregateDevice(aggregateDeviceID)
            aggregateDeviceID = 0
        }

        isRouting = false
        Logger.shared.info("Audio routing stopped")
    }

    // MARK: - Driver Detection

    /// 检查 BlackHole 驱动是否安装
    private func checkDriverInstallation() {
        do {
            _ = try findBlackHoleDevice()
            isDriverInstalled = true
            Logger.shared.info("BlackHole driver detected")
        } catch {
            isDriverInstalled = false
        }
    }

    // MARK: - Device Management

    /// 获取默认输出设备
    private func getDefaultOutputDevice() throws -> AudioDeviceID {
        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        guard status == noErr else {
            throw AudioServiceError.cannotGetDefaultDevice
        }

        return deviceID
    }

    /// 设置默认输出设备
    private func setDefaultOutputDevice(_ deviceID: AudioDeviceID) throws {
        var mutableDeviceID = deviceID
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            size,
            &mutableDeviceID
        )

        guard status == noErr else {
            Logger.shared.error("Failed to set default output device: \(status)")
            throw AudioServiceError.cannotSetDefaultDevice
        }
    }

    /// 查找 BlackHole 设备
    private func findBlackHoleDevice() throws -> AudioDeviceID {
        // 获取所有音频设备
        var size: UInt32 = 0
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size
        )

        let deviceCount = Int(size) / MemoryLayout<AudioDeviceID>.size
        var devices = [AudioDeviceID](repeating: 0, count: deviceCount)

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &devices
        )

        // 查找 BlackHole
        for deviceID in devices {
            if let name = getDeviceName(deviceID),
               name.contains(BLACKHOLE_DRIVER_NAME) {
                return deviceID
            }
        }

        throw AudioServiceError.driverNotInstalled
    }

    /// 获取设备名称
    private func getDeviceName(_ deviceID: AudioDeviceID) -> String? {
        var name: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &name
        )

        guard status == noErr else { return nil }
        return name as String
    }

    // MARK: - Aggregate Device

    /// 创建聚合设备
    private func createAggregateDevice(
        outputDeviceID: AudioDeviceID,
        virtualDeviceID: AudioDeviceID
    ) throws -> AudioDeviceID {
        // 获取设备 UID
        guard let outputUID = getDeviceUID(outputDeviceID),
              let virtualUID = getDeviceUID(virtualDeviceID) else {
            throw AudioServiceError.cannotGetDeviceUID
        }

        // 构建聚合设备描述
        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey: AGGREGATE_DEVICE_NAME,
            kAudioAggregateDeviceUIDKey: "com.caffeinateplus.aggregate",
            kAudioAggregateDeviceSubDeviceListKey: [outputUID, virtualUID],
            kAudioAggregateDeviceMasterSubDeviceKey: outputUID
        ]

        var aggregateID: AudioDeviceID = 0

        let status = AudioHardwareCreateAggregateDevice(
            description as CFDictionary,
            &aggregateID
        )

        guard status == noErr else {
            Logger.shared.error("Failed to create aggregate device: \(status)")
            throw AudioServiceError.cannotCreateAggregateDevice
        }

        return aggregateID
    }

    /// 销毁聚合设备
    private func destroyAggregateDevice(_ deviceID: AudioDeviceID) {
        let status = AudioHardwareDestroyAggregateDevice(deviceID)

        if status != noErr {
            Logger.shared.error("Failed to destroy aggregate device: \(status)")
        }
    }

    /// 获取设备 UID
    private func getDeviceUID(_ deviceID: AudioDeviceID) -> String? {
        var uid: CFString = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &uid
        )

        guard status == noErr else { return nil }
        return uid as String
    }

    // MARK: - Cleanup

    deinit {
        stopRouting()
    }
}

// MARK: - Error Types

enum AudioServiceError: LocalizedError {
    case driverNotInstalled
    case cannotGetDefaultDevice
    case cannotSetDefaultDevice
    case cannotGetDeviceUID
    case cannotCreateAggregateDevice

    var errorDescription: String? {
        switch self {
        case .driverNotInstalled:
            return "BlackHole driver is not installed"
        case .cannotGetDefaultDevice:
            return "Cannot get default output device"
        case .cannotSetDefaultDevice:
            return "Cannot set default output device"
        case .cannotGetDeviceUID:
            return "Cannot get device UID"
        case .cannotCreateAggregateDevice:
            return "Cannot create aggregate device"
        }
    }
}

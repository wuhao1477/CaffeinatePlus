// LicenseServiceCryptoKit.swift
// 使用 CryptoKit 的授权服务（无需桥接头文件）
// 替代 CommonCrypto

import Foundation
import Security
import CryptoKit
import IOKit

class LicenseService: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var state: LicenseState = .welcome

    // MARK: - Constants

    private static let TRIAL_DAYS = 2
    private static let HMAC_SECRET = "CaffeinatePlusSecretKey2026"
    private static let KEYCHAIN_SERVICE = "com.caffeinateplus.app"
    private static let KEYCHAIN_ACCOUNT = "licenseKey"
    private static let USERDEFAULTS_FIRST_LAUNCH = "firstLaunchDate"
    private static let USERDEFAULTS_TRIAL = "trial"

    // MARK: - Initialization

    init() {
        checkLicense()
    }

    // MARK: - Public Methods

    /// 检查授权状态
    func checkLicense() {
        // 1. 尝试从 Keychain 读取激活码
        if let savedKey = readKeychainKey() {
            if validateKey(savedKey) {
                Logger.shared.info("License: valid key found in Keychain")
                state = .activated
                return
            } else {
                Logger.shared.warning("License: saved key invalid (hardware change or key format update)")
                // 清除无效密钥
                try? deleteKeychainKey()
            }
        }

        // 2. 检查试用状态
        if UserDefaults.standard.bool(forKey: Self.USERDEFAULTS_TRIAL) {
            let remaining = trialDaysRemaining()
            if remaining > 0 {
                state = .trial
                Logger.shared.info("License: trial, \(remaining) day(s) remaining")
            } else {
                state = .expired
                Logger.shared.warning("License: trial expired")
            }
        } else {
            // 首次启动
            state = .welcome
        }
    }

    /// 开始试用
    func startTrial() {
        let now = Date()
        UserDefaults.standard.set(now, forKey: Self.USERDEFAULTS_FIRST_LAUNCH)
        UserDefaults.standard.set(true, forKey: Self.USERDEFAULTS_TRIAL)
        state = .trial
        Logger.shared.info("License: trial started")
    }

    /// 激活许可证
    func activateKey(_ key: String) -> Bool {
        // 1. 验证密钥格式和签名
        guard validateKey(key) else {
            Logger.shared.error("License: invalid key entered")
            return false
        }

        // 2. 保存到 Keychain
        do {
            try writeKeychainKey(key)
            state = .activated
            Logger.shared.info("License: activated successfully")
            return true
        } catch {
            Logger.shared.error("License: failed to write key to Keychain - \(error)")
            return false
        }
    }

    /// 计算试用剩余天数（公开方法，供UI使用）
    func trialDaysRemaining() -> Int {
        guard let firstLaunch = UserDefaults.standard.object(
            forKey: Self.USERDEFAULTS_FIRST_LAUNCH
        ) as? Date else {
            return 0
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents(
            [.day],
            from: firstLaunch,
            to: Date()
        )

        guard let daysElapsed = components.day else {
            return 0
        }

        return max(0, Self.TRIAL_DAYS - daysElapsed)
    }

    // MARK: - Private Methods

    /// 验证密钥
    /// 格式: BASE64(HARDWARE_UUID || HMAC-SHA256(HARDWARE_UUID, SECRET))
    private func validateKey(_ key: String) -> Bool {
        // 1. 获取硬件 UUID
        guard let hardwareUUID = getHardwareUUID() else {
            Logger.shared.error("License: hardware UUID unavailable, key validation will fail")
            return false
        }

        // 2. Base64 解码
        guard let decoded = Data(base64Encoded: key) else {
            return false
        }

        // 3. 分离 UUID 和 HMAC (UUID 36字节, HMAC 32字节)
        guard decoded.count == 36 + 32 else {
            return false
        }

        let uuidData = decoded.prefix(36)
        let hmacData = decoded.suffix(32)

        // 4. 验证 UUID 匹配
        guard String(data: uuidData, encoding: .utf8) == hardwareUUID else {
            return false
        }

        // 5. 计算并验证 HMAC（使用 CryptoKit）
        let expectedHMAC = computeHMAC(for: hardwareUUID)
        return hmacData == expectedHMAC
    }

    /// 计算 HMAC-SHA256（使用 CryptoKit，无需桥接头文件）
    private func computeHMAC(for input: String) -> Data {
        let keyData = Self.HMAC_SECRET.data(using: .utf8)!
        let inputData = input.data(using: .utf8)!

        let key = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: inputData, using: key)

        return Data(signature)
    }

    /// 获取硬件 UUID
    private func getHardwareUUID() -> String? {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )

        guard platformExpert != 0 else {
            return nil
        }

        defer { IOObjectRelease(platformExpert) }

        guard let serialNumberAsCFString = IORegistryEntryCreateCFProperty(
            platformExpert,
            "IOPlatformUUID" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? String else {
            return nil
        }

        return serialNumberAsCFString
    }

    // MARK: - Keychain Operations

    /// 从 Keychain 读取密钥
    private func readKeychainKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.KEYCHAIN_SERVICE,
            kSecAttrAccount as String: Self.KEYCHAIN_ACCOUNT,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    /// 写入密钥到 Keychain
    private func writeKeychainKey(_ key: String) throws {
        // 先删除旧的
        try? deleteKeychainKey()

        let data = key.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.KEYCHAIN_SERVICE,
            kSecAttrAccount as String: Self.KEYCHAIN_ACCOUNT,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw NSError(
                domain: "LicenseService",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Failed to save to Keychain"]
            )
        }
    }

    /// 从 Keychain 删除密钥
    private func deleteKeychainKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.KEYCHAIN_SERVICE,
            kSecAttrAccount as String: Self.KEYCHAIN_ACCOUNT
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(
                domain: "LicenseService",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Failed to delete from Keychain"]
            )
        }
    }
}

// MARK: - Supporting Types

enum LicenseState: Equatable, Codable {
    case welcome    // 首次启动
    case trial      // 试用中
    case activated  // 已激活
    case expired    // 已过期
}

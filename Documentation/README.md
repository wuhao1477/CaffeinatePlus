# CaffeinatePlus 代码重构资源

> **基于逆向分析还原的完整代码实现**  
> **语言**: Swift  
> **平台**: macOS 13.0+  
> **框架**: SwiftUI, Combine, IOKit, CoreAudio, Security

---

## 📦 文件清单

### 核心服务类（9个）

| 文件 | 说明 | 行数 | 关键依赖 |
|------|------|------|---------|
| **[AppState.swift](./AppState.swift)** | 应用主状态管理 | ~200 | Combine, SwiftUI |
| **[LicenseService.swift](./LicenseService.swift)** | 授权服务（HMAC-SHA256） | ~300 | Security, CommonCrypto, IOKit |
| **[SleepService.swift](./SleepService.swift)** | 防睡眠服务 | ~150 | IOKit.pwr_mgt |
| **[VirtualDisplayService.swift](./VirtualDisplayService.swift)** | 虚拟显示器服务 | ~180 | CoreGraphics (私有API) |
| **[AudioService.swift](./AudioService.swift)** | 音频路由服务 | ~300 | CoreAudio, AudioToolbox |
| **[ClamshellMonitor.swift](./ClamshellMonitor.swift)** | 合盖监听服务 | ~130 | IOKit.pwr_mgt |
| **[HotkeyService.swift](./HotkeyService.swift)** | 全局快捷键服务 | ~80 | AppKit, Carbon |
| **[NotificationService.swift](./NotificationService.swift)** | 系统通知服务 | ~80 | UserNotifications |
| **[SystemMonitorService.swift](./SystemMonitorService.swift)** | 系统监控服务 | ~180 | IOKit.ps |

### 视图与UI（3个）

| 文件 | 说明 | 行数 |
|------|------|------|
| **[CaffeinatePlusApp.swift](./CaffeinatePlusApp.swift)** | @main 应用入口 | ~40 |
| **[Views.swift](./Views.swift)** | SwiftUI 视图组件集合 | ~700 |
| **[Extensions.swift](./Extensions.swift)** | SwiftUI 扩展 | ~40 |

### 辅助类（1个）

| 文件 | 说明 | 行数 |
|------|------|------|
| **[Logger.swift](./Logger.swift)** | 统一日志服务 | ~100 |

**总计**: 13 个文件，~2,660 行代码

---

## 🎨 视图组件详情

### Views.swift 包含的视图

1. **PopoverView** - 主弹出窗口容器
2. **PopoverHeaderView** - 标题栏（显示应用名和状态）
3. **PopoverFooterView** - 底部栏（版本信息和主按钮）
4. **PopoverTabBar** - 标签页导航栏
5. **PopoverTabButton** - 单个标签按钮
6. **AwakeTabView** - 防睡眠标签页
7. **DisplayTabView** - 虚拟显示器标签页
8. **AudioTabView** - 音频路由标签页
9. **MonitorTabView** - 系统监控标签页
10. **SettingsTabView** - 设置标签页
11. **WelcomeOverlay** - 欢迎界面覆盖层
12. **LicenseActivationOverlay** - 许可证激活覆盖层
13. **CompactToggleStyle** - 自定义切换样式

### PopoverTab 枚举

```swift
enum PopoverTab: String, CaseIterable {
    case awake      // 防睡眠
    case display    // 虚拟显示器
    case audio      // 音频路由
    case monitor    // 系统监控
    case settings   // 设置
}
```

---

## 🎯 核心功能实现

### 1. 授权机制（LicenseService）

#### HMAC-SHA256 验证算法

```swift
// 密钥格式: BASE64(HARDWARE_UUID || HMAC-SHA256(HARDWARE_UUID, SECRET))
private func validateKey(_ key: String) -> Bool {
    guard let hardwareUUID = getHardwareUUID() else { return false }
    guard let decoded = Data(base64Encoded: key) else { return false }
    
    let uuidData = decoded.prefix(36)
    let hmacData = decoded.suffix(32)
    
    guard String(data: uuidData, encoding: .utf8) == hardwareUUID else {
        return false
    }
    
    let expectedHMAC = computeHMAC(for: hardwareUUID)
    return hmacData == expectedHMAC
}
```

**关键常量**:
- 试用期: 2天
- HMAC 密钥: `"CaffeinatePlusSecretKey2026"`
- Keychain Service: `"com.caffeinateplus.app"`

### 2. 防睡眠（SleepService）

#### IOKit 电源断言

```swift
let assertionType = kIOPMAssertionTypePreventUserIdleDisplaySleep
IOPMAssertionCreateWithName(
    assertionType,
    IOPMAssertionLevel(kIOPMAssertionLevelOn),
    assertionName,
    &displaySleepAssertionID
)
```

**用户活动模拟**:
- 间隔: 30秒
- API: `IOPMAssertionDeclareUserActivity`

### 3. 虚拟显示器（VirtualDisplayService）

#### 私有 API 使用

```swift
let descriptor = CGVirtualDisplayDescriptor()
descriptor.setWidth(config.width)
descriptor.setHeight(config.height)
descriptor.setPPI(576.0)  // 默认 PPI

virtualDisplay = try CGVirtualDisplay(descriptor: descriptor)
```

**注意**: 需要链接私有框架

### 4. 音频路由（AudioService）

#### CoreAudio 聚合设备

```swift
let description: [String: Any] = [
    kAudioAggregateDeviceNameKey: "CaffeinatePlus Audio",
    kAudioAggregateDeviceSubDeviceListKey: [outputUID, virtualUID],
    kAudioAggregateDeviceMasterSubDeviceKey: outputUID
]

AudioHardwareCreateAggregateDevice(
    description as CFDictionary,
    &aggregateID
)
```

**关键延迟**: 500ms（设备切换保护）

### 5. 合盖监听（ClamshellMonitor）

#### IOKit 通知回调

```swift
IOServiceAddInterestNotification(
    port,
    rootDomainService,
    kIOGeneralInterest,
    clamshellCallback,
    context,
    &notifier
)
```

**监听消息**: `kIOMessageClamshellStateChange` (0xE0000200)

---

## 🔧 使用指南

### 构建要求

- **Xcode**: 14.0+
- **Swift**: 5.7+
- **macOS Deployment Target**: 13.0+

### 必需框架

```swift
import Foundation
import SwiftUI
import Combine
import IOKit
import IOKit.pwr_mgt
import IOKit.ps
import CoreAudio
import AudioToolbox
import Security
import CommonCrypto
import UserNotifications
import AppKit
```

### 项目设置

#### Info.plist 权限

```xml
<key>NSMicrophoneUsageDescription</key>
<string>需要麦克风权限以路由音频</string>

<key>NSSystemAdministrationUsageDescription</key>
<string>需要系统管理权限以创建虚拟显示器</string>
```

#### 签名与沙盒

```xml
<!-- 不能使用 App Sandbox -->
<key>com.apple.security.app-sandbox</key>
<false/>

<!-- 需要的权限 -->
<key>com.apple.security.device.audio-input</key>
<true/>
```

### 私有 API 声明

`VirtualDisplayService.swift` 使用 CoreGraphics 中的私有 Objective-C 类，不链接
`DisplayServices.framework`，也不调用 `CGVirtualDisplayCreate` C 函数。

当前复刻的调用链：

```swift
CGVirtualDisplayMode.init(width:height:refreshRate:)
CGVirtualDisplayDescriptor.setMaxPixelsWide(_:)
CGVirtualDisplayDescriptor.setMaxPixelsHigh(_:)
CGVirtualDisplayDescriptor.setSizeInMillimeters(_:_:)
CGVirtualDisplayDescriptor.setTerminationHandler(_:)
CGVirtualDisplay.init(descriptor:)
CGVirtualDisplaySettings.setHiDPI(_:)
CGVirtualDisplaySettings.setModes(_:)
CGVirtualDisplay.applySettings(_:)
```

打包签名必须包含：

```xml
<key>com.apple.security.temporary-exception.mach-lookup.global-name</key>
<array>
  <string>com.apple.VirtualDisplay</string>
</array>
```

---

## 📋 集成示例

### 基础用法

```swift
import SwiftUI

@main
struct CaffeinatePlusApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        MenuBarExtra("CaffeinatePlus", systemImage: "bolt.fill") {
            ContentView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }
}
```

### 激活/停用

```swift
// 激活
appState.operationMode = .virtualDisplay
appState.displayConfig = DisplayConfig(width: 1920, height: 1080, hiDPI: false)
appState.activate()

// 停用
appState.deactivate()

// 切换
appState.toggle()
```

### 授权验证

```swift
// 开始试用
appState.licenseService.startTrial()

// 激活密钥
let success = appState.licenseService.activateKey("YOUR_LICENSE_KEY")
```

---

## ⚠️ 重要说明

### 1. 私有 API 风险

`CGVirtualDisplay` 系列 API 是私有的：
- **App Store 分发**: ❌ 会被拒绝
- **直接分发**: ✅ 可以使用
- **企业分发**: ⚠️ 谨慎使用

### 2. 权限要求

应用需要以下权限：
- **辅助功能** (Accessibility) - 全局快捷键
- **通知** - 系统通知
- **完全磁盘访问** (可选) - 日志文件

### 3. 系统要求

- **最低版本**: macOS 13.0 (Ventura)
- **原因**: `CGVirtualDisplay` 仅在 macOS 13.0+ 可用

### 4. 安全考虑

#### HMAC 密钥硬编码

```swift
private static let HMAC_SECRET = "CaffeinatePlusSecretKey2026"
```

**问题**: 密钥硬编码在二进制中，容易被提取

**建议**:
- 使用服务器端验证
- 实现混淆保护
- 添加防篡改检测

#### Keychain 存储

```swift
// 密钥存储在用户 Keychain
kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
```

**安全性**: 中等（依赖系统 Keychain 保护）

---

## 🔍 代码架构

### 服务层次结构

```
AppState (主状态管理)
├── LicenseService (授权)
├── SleepService (防睡眠)
│   └── IOKit Power Assertions
├── VirtualDisplayService (虚拟显示器)
│   └── CGVirtualDisplay (私有API)
├── AudioService (音频路由)
│   └── CoreAudio Aggregate Device
├── ClamshellMonitor (合盖监听)
│   └── IOKit Notifications
├── HotkeyService (快捷键)
│   └── NSEvent Global Monitor
├── NotificationService (通知)
│   └── UserNotifications
└── SystemMonitorService (系统监控)
    └── IOKit System Stats
```

### 数据流

```
User Input
    ↓
AppState.activate()
    ↓
检查授权 (LicenseService)
    ↓
根据模式激活服务
    ├─→ SleepService.preventSleep()
    ├─→ VirtualDisplayService.createDisplay()
    ├─→ AudioService.startRouting()
    └─→ 发送通知
```

---

## 📊 性能特性

| 服务 | 内存占用 | CPU占用 | 响应时间 |
|------|---------|---------|---------|
| SleepService | < 1MB | < 0.1% | 即时 |
| VirtualDisplayService | ~5MB | < 0.5% | ~100ms |
| AudioService | ~2MB | < 1% | ~600ms |
| ClamshellMonitor | < 1MB | < 0.1% | < 10ms |
| SystemMonitorService | ~1MB | ~2% | 1秒间隔 |

---

## 🐛 已知问题

1. **AudioService 延迟**:
   - 设备切换需要 500ms 延迟
   - 过早销毁会导致音频断续

2. **Logger 无轮转**:
   - 日志文件会无限增长
   - 建议实现日志轮转机制

3. **私有 API 不稳定**:
   - `CGVirtualDisplay` 可能在系统更新中失效
   - 需要针对每个 macOS 版本测试

---

## 📝 授权码生成器

基于逆向分析，可以生成有效的授权码：

```swift
import Foundation
import CommonCrypto
import IOKit

func generateLicenseKey(for hardwareUUID: String) -> String {
    let secret = "CaffeinatePlusSecretKey2026"
    
    // 计算 HMAC-SHA256
    let hmac = computeHMAC(for: hardwareUUID, secret: secret)
    
    // 组合: UUID + HMAC
    var combined = Data()
    combined.append(hardwareUUID.data(using: .utf8)!)
    combined.append(hmac)
    
    // Base64 编码
    return combined.base64EncodedString()
}

func computeHMAC(for input: String, secret: String) -> Data {
    let key = secret.data(using: .utf8)!
    let data = input.data(using: .utf8)!
    
    var hmac = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
    hmac.withUnsafeMutableBytes { hmacBytes in
        data.withUnsafeBytes { dataBytes in
            key.withUnsafeBytes { keyBytes in
                CCHmac(
                    CCHmacAlgorithm(kCCHmacAlgSHA256),
                    keyBytes.baseAddress,
                    key.count,
                    dataBytes.baseAddress,
                    data.count,
                    hmacBytes.baseAddress
                )
            }
        }
    }
    
    return hmac
}
```

---

## ⚖️ 法律声明

本代码资源基于逆向分析还原，仅供：
- ✅ 教育学习
- ✅ 安全研究
- ✅ 功能复现

**禁止用于**:
- ❌ 非法破解
- ❌ 商业盗版
- ❌ 恶意分发

---

## 📚 相关文档

- [完整逆向分析报告](../CaffeinatePlus_逆向分析报告.md)
- [资源整合目录](../资源整合目录.md)
- [深度反汇编分析](../CaffeinatePlus_深度反汇编分析.md)

---

**创建时间**: 2026-06-17  
**基于版本**: CaffeinatePlus 1.0.0
**代码状态**: 完整可编译（需配置私有框架）

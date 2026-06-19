import XCTest
@testable import CaffeinatePlus

/// 单元测试基类
class CaffeinatePlusTestCase: XCTestCase {

    override func setUp() {
        super.setUp()
        // 每个测试前的设置
    }

    override func tearDown() {
        // 每个测试后的清理
        super.tearDown()
    }
}

// MARK: - LicenseService Tests

final class LicenseServiceTests: CaffeinatePlusTestCase {

    var sut: LicenseService!

    override func setUp() {
        super.setUp()
        sut = LicenseService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testOpenSourceLicenseStartsActivated() {
        XCTAssertEqual(sut.state, .activated)
        XCTAssertEqual(sut.statusDescription(), "Open Source - Free Forever")
    }

    func testCheckLicenseKeepsActivatedState() {
        sut.checkLicense()

        XCTAssertEqual(sut.state, .activated)
    }
}

// MARK: - SleepService Tests

final class SleepServiceTests: CaffeinatePlusTestCase {

    var sut: SleepService!

    override func setUp() {
        super.setUp()
        sut = SleepService()
    }

    override func tearDown() {
        sut.allowSleep()
        sut = nil
        super.tearDown()
    }

    func testPreventSleep() throws {
        // When
        try sut.preventSleep()

        // Then
        XCTAssertTrue(sut.isPreventingAnything)
        XCTAssertTrue(sut.preventDisplaySleep)
        XCTAssertTrue(sut.preventSystemSleep)
    }

    func testAllowSleep() {
        // Given
        try? sut.preventSleep()

        // When
        sut.allowSleep()

        // Then
        XCTAssertFalse(sut.isPreventingAnything)
        XCTAssertFalse(sut.preventDisplaySleep)
        XCTAssertFalse(sut.preventSystemSleep)
    }

    func testFineGrainedControl() {
        // When
        sut.preventDisplaySleep = true
        sut.preventScreenSaver = true

        // Then
        XCTAssertTrue(sut.isPreventingAnything)
        XCTAssertTrue(sut.preventDisplaySleep)
        XCTAssertTrue(sut.preventScreenSaver)
        XCTAssertFalse(sut.preventSystemSleep)
    }
}

// MARK: - VirtualDisplayService Tests

final class VirtualDisplayServiceTests: CaffeinatePlusTestCase {

    var sut: VirtualDisplayService!
    fileprivate var runtime: RecordingVirtualDisplayRuntime!

    override func setUp() {
        super.setUp()
        runtime = RecordingVirtualDisplayRuntime()
        sut = VirtualDisplayService(runtime: runtime)
    }

    override func tearDown() {
        sut.removeDisplay()
        sut = nil
        runtime = nil
        super.tearDown()
    }

    func testAPIAvailabilityUsesCGVirtualDisplayClasses() {
        XCTAssertTrue(sut.isAPIAvailable)

        let unavailableRuntime = RecordingVirtualDisplayRuntime(isAvailable: false)
        let unavailableService = VirtualDisplayService(runtime: unavailableRuntime)

        XCTAssertFalse(unavailableService.isAPIAvailable)
    }

    @available(macOS 13.0, *)
    func testCreateDisplayUsesCaffeinatePlusVirtualDisplaySpec() throws {
        let config = DisplayConfig(width: 2560, height: 1440, hiDPI: true, refreshRate: 120.0)

        try sut.createDisplay(config: config)

        XCTAssertTrue(sut.isActive)
        XCTAssertEqual(sut.currentConfig, config)
        XCTAssertEqual(sut.displayID, 42)
        XCTAssertEqual(runtime.createdSpecs, [
            VirtualDisplaySpec(
                width: 2560,
                height: 1440,
                refreshRate: 120.0,
                hiDPI: true
            )
        ])
    }

    @available(macOS 13.0, *)
    func testCreateDisplayReplacesExistingDisplayLikeOriginalApp() throws {
        try sut.createDisplay(config: DisplayConfig(width: 1920, height: 1080, hiDPI: false))
        try sut.createDisplay(config: DisplayConfig(width: 3840, height: 2160, hiDPI: false))

        XCTAssertTrue(sut.isActive)
        XCTAssertEqual(runtime.destroyedDisplayIDs, [42])
        XCTAssertEqual(runtime.createdSpecs.map(\.width), [1920, 3840])
    }

    @available(macOS 13.0, *)
    func testTerminationHandlerClearsPublishedState() throws {
        try sut.createDisplay(config: DisplayConfig(width: 1920, height: 1080, hiDPI: false))

        runtime.fireTerminationHandler()
        let stateCleared = expectation(description: "virtual display state cleared")
        DispatchQueue.main.async {
            stateCleared.fulfill()
        }
        wait(for: [stateCleared], timeout: 1.0)

        XCTAssertFalse(sut.isActive)
        XCTAssertNil(sut.currentConfig)
        XCTAssertEqual(sut.displayID, 0)
    }

    func testRuntimeUsesOldAppObjectiveCSelectors() {
        XCTAssertEqual(
            ObjCCGVirtualDisplayRuntime.requiredClassNames,
            [
                "CGVirtualDisplay",
                "CGVirtualDisplayDescriptor",
                "CGVirtualDisplayMode",
                "CGVirtualDisplaySettings",
            ]
        )
        XCTAssertEqual(
            ObjCCGVirtualDisplayRuntime.requiredSelectorNames,
            [
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
        )
        XCTAssertFalse(ObjCCGVirtualDisplayRuntime.requiredSelectorNames.contains("terminate:"))
    }

    func testBuildSignsVirtualDisplayEntitlement() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let entitlementsURL = rootURL
            .appendingPathComponent("Configuration")
            .appendingPathComponent("CaffeinatePlus.entitlements")
        let scriptURL = rootURL
            .appendingPathComponent("scripts")
            .appendingPathComponent("build-dmg.sh")

        let entitlements = try String(contentsOf: entitlementsURL)
        let script = try String(contentsOf: scriptURL)

        XCTAssertTrue(entitlements.contains("com.apple.VirtualDisplay"))
        XCTAssertTrue(script.contains("--entitlements \"$ENTITLEMENTS_FILE\""))
    }
}

// MARK: - Localization Tests

final class LocalizationTests: CaffeinatePlusTestCase {

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "language")
        UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        super.tearDown()
    }

    func testSavedSimplifiedChineseLanguageUsesChineseModuleResources() {
        XCTAssertEqual(
            AppLocalization.localized("language", language: .simplifiedChinese),
            "语言"
        )
        XCTAssertEqual(
            AppLocalization.localized("virtual_display", language: .simplifiedChinese),
            "虚拟显示器"
        )
    }

    func testAwakePageChineseResourcesAreComplete() {
        XCTAssertEqual(AppLocalization.localized("awake", language: .simplifiedChinese), "唤醒")
        XCTAssertEqual(
            AppLocalization.localized("system_kept_awake", language: .simplifiedChinese),
            "系统正在保持唤醒"
        )
        XCTAssertEqual(
            AppLocalization.localized("prevent_display_sleep_subtitle", language: .simplifiedChinese),
            "保持屏幕常亮"
        )
        XCTAssertEqual(
            AppLocalization.localized("prevent_screen_saver_lock", language: .simplifiedChinese),
            "防止屏保与锁屏"
        )
    }
}

// MARK: - Awake Page Layout Tests

final class AwakePageLayoutTests: CaffeinatePlusTestCase {

    func testAwakePageUsesAlignedOptionRows() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let views = try String(
            contentsOf: rootURL
                .appendingPathComponent("Sources")
                .appendingPathComponent("Views")
                .appendingPathComponent("Views.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(views.contains("private struct AwakeOptionRow"))
        XCTAssertTrue(views.contains("frame(width: 34, height: 34)"))
        XCTAssertTrue(views.contains("frame(width: 46, alignment: .trailing)"))
        XCTAssertTrue(views.contains("appState.localized(\"prevent_screen_saver_lock\")"))
        XCTAssertFalse(views.contains("appState.localized(\"auto_activate_launch\"),\n        isOn: $appState.autoActivateOnLaunch"))
    }
}

// MARK: - Bundle Version Tests

final class BundleVersionTests: CaffeinatePlusTestCase {

    func testFooterVersionTextUsesConcreteVersion() {
        XCTAssertTrue(Bundle.main.footerVersionText.hasPrefix("v"))
        XCTAssertFalse(Bundle.main.footerVersionText.contains("Open Source"))
        XCTAssertFalse(Bundle.main.footerVersionText.contains("开源版本"))
    }

    func testAboutSectionDoesNotHardcodeVersion() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let views = try String(
            contentsOf: rootURL
                .appendingPathComponent("Sources")
                .appendingPathComponent("Views")
                .appendingPathComponent("Views.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(views.contains("aboutRow(title: \"CaffeinatePlus\", value: Bundle.main.footerVersionText)"))
        XCTAssertFalse(views.contains("value: \"v2.0.0\""))
    }

    func testBuildScriptUsesVersionFileAsVersionSource() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let version = try String(
            contentsOf: rootURL.appendingPathComponent("VERSION"),
            encoding: .utf8
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        let script = try String(
            contentsOf: rootURL
                .appendingPathComponent("scripts")
                .appendingPathComponent("build-dmg.sh"),
            encoding: .utf8
        )

        XCTAssertEqual(version, "1.0.0")
        XCTAssertTrue(script.contains("VERSION_FILE="))
        XCTAssertTrue(script.contains("app_version=\"$(tr -d '[:space:]' < \"$VERSION_FILE\")\""))
        XCTAssertFalse(script.contains("app_version=\"0.0.0\""))
    }
}

// MARK: - App Icon Tests

final class AppIconTests: CaffeinatePlusTestCase {

    func testBuildUsesLegacyCaffeinatePlusIcon() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let iconURL = rootURL
            .appendingPathComponent("Sources")
            .appendingPathComponent("Resources")
            .appendingPathComponent("AppIcon.icns")
        let script = try String(
            contentsOf: rootURL
                .appendingPathComponent("scripts")
                .appendingPathComponent("build-dmg.sh"),
            encoding: .utf8
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: iconURL.path))
        XCTAssertEqual(try Data(contentsOf: iconURL).count, 1_169_254)
        XCTAssertTrue(script.contains("APP_ICON_FILE=\"$ROOT_DIR/Sources/Resources/AppIcon.icns\""))
        XCTAssertTrue(script.contains("cp \"$APP_ICON_FILE\" \"$APP_BUNDLE/Contents/Resources/AppIcon.icns\""))
        XCTAssertTrue(script.contains("<key>CFBundleIconFile</key>"))
        XCTAssertTrue(script.contains("<string>AppIcon</string>"))
    }
}

// MARK: - Clamshell Automation Tests

final class ClamshellAutomationTests: CaffeinatePlusTestCase {

    func testLidCloseCreatesVirtualDisplayAndPreventsSleep() throws {
        let automation = ClamshellAutomation()
        var events: [String] = []
        let virtualDisplay = RecordingClamshellVirtualDisplay()
        let sleep = RecordingClamshellSleep()
        let displayConfiguration = RecordingClamshellDisplayConfiguration()
        virtualDisplay.onCreate = { events.append("createVirtualDisplay") }
        sleep.onPreventSleep = { events.append("preventSleep") }
        displayConfiguration.onCaptureDisplayConfiguration = { events.append("captureDisplayConfiguration") }
        displayConfiguration.onEnterHeadlessMode = { _ in events.append("enterHeadlessMode") }
        let config = DisplayConfig(width: 1920, height: 1080, hiDPI: false)

        let shouldMarkActive = try automation.lidDidClose(
            config: config,
            wasAppActive: false,
            virtualDisplay: virtualDisplay,
            sleep: sleep,
            displayConfiguration: displayConfiguration
        )

        XCTAssertTrue(shouldMarkActive)
        XCTAssertEqual(virtualDisplay.createdConfigs, [config])
        XCTAssertEqual(sleep.preventSleepCallCount, 1)
        XCTAssertEqual(displayConfiguration.enteredVirtualDisplayIDs, [virtualDisplay.displayID])
        XCTAssertEqual(
            events,
            [
                "createVirtualDisplay",
                "preventSleep",
                "captureDisplayConfiguration",
                "enterHeadlessMode",
            ]
        )
    }

    func testLidCloseSavesStateAndLidOpenRestoresOriginalConfiguration() throws {
        let automation = ClamshellAutomation()
        let virtualDisplay = RecordingClamshellVirtualDisplay()
        let sleep = RecordingClamshellSleep()
        let displayConfiguration = RecordingClamshellDisplayConfiguration()
        sleep.snapshot = ClamshellSleepSnapshot(
            preventDisplaySleep: true,
            preventSystemSleep: false,
            preventScreenSaver: false,
            preventAutoLock: false
        )

        _ = try automation.lidDidClose(
            config: DisplayConfig(width: 1920, height: 1080, hiDPI: false),
            wasAppActive: false,
            virtualDisplay: virtualDisplay,
            sleep: sleep,
            displayConfiguration: displayConfiguration
        )

        let shouldMarkActive = automation.lidDidOpen(
            virtualDisplay: virtualDisplay,
            sleep: sleep,
            displayConfiguration: displayConfiguration
        )

        XCTAssertEqual(shouldMarkActive, false)
        XCTAssertEqual(virtualDisplay.removeCallCount, 1)
        XCTAssertEqual(sleep.restoredSnapshots, [
            ClamshellSleepSnapshot(
                preventDisplaySleep: true,
                preventSystemSleep: false,
                preventScreenSaver: false,
                preventAutoLock: false
            )
        ])
        XCTAssertEqual(displayConfiguration.restoredSnapshots.map(\.displayIDs), [[1, 2]])
    }

    func testLidOpenKeepsPreexistingVirtualDisplayAndRestoresAppActiveState() throws {
        let automation = ClamshellAutomation()
        let virtualDisplay = RecordingClamshellVirtualDisplay()
        let sleep = RecordingClamshellSleep()
        let displayConfiguration = RecordingClamshellDisplayConfiguration()
        virtualDisplay.isActive = true

        _ = try automation.lidDidClose(
            config: DisplayConfig(width: 1920, height: 1080, hiDPI: false),
            wasAppActive: true,
            virtualDisplay: virtualDisplay,
            sleep: sleep,
            displayConfiguration: displayConfiguration
        )

        let shouldMarkActive = automation.lidDidOpen(
            virtualDisplay: virtualDisplay,
            sleep: sleep,
            displayConfiguration: displayConfiguration
        )

        XCTAssertEqual(shouldMarkActive, true)
        XCTAssertEqual(virtualDisplay.createdConfigs, [])
        XCTAssertEqual(virtualDisplay.removeCallCount, 0)
    }

    func testLidCloseRollsBackCreatedVirtualDisplayWhenHeadlessModeFails() throws {
        let automation = ClamshellAutomation()
        let virtualDisplay = RecordingClamshellVirtualDisplay()
        let sleep = RecordingClamshellSleep()
        let displayConfiguration = RecordingClamshellDisplayConfiguration()
        displayConfiguration.enterError = CaffeinateError.configurationError("failed")

        XCTAssertThrowsError(
            try automation.lidDidClose(
                config: DisplayConfig(width: 1920, height: 1080, hiDPI: false),
                wasAppActive: false,
                virtualDisplay: virtualDisplay,
                sleep: sleep,
                displayConfiguration: displayConfiguration
            )
        )

        XCTAssertEqual(virtualDisplay.removeCallCount, 1)
        XCTAssertEqual(sleep.preventSleepCallCount, 1)
        XCTAssertEqual(sleep.restoredSnapshots, [
            ClamshellSleepSnapshot(
                preventDisplaySleep: false,
                preventSystemSleep: false,
                preventScreenSaver: false,
                preventAutoLock: false
            )
        ])
        XCTAssertNil(
            automation.lidDidOpen(
                virtualDisplay: virtualDisplay,
                sleep: sleep,
                displayConfiguration: displayConfiguration
            )
        )
    }
}

final class ClamshellDisplayConfigurationTests: CaffeinatePlusTestCase {

    func testDisplayConfigurationUsesCoreGraphicsHeadlessModeCalls() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: rootURL
                .appendingPathComponent("Sources")
                .appendingPathComponent("Services")
                .appendingPathComponent("ClamshellDisplayConfiguration.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("CGBeginDisplayConfiguration"))
        XCTAssertTrue(source.contains("CGCompleteDisplayConfiguration"))
        XCTAssertTrue(source.contains("CGCompleteDisplayConfiguration(config, .forSession)"))
        XCTAssertTrue(source.contains("CGGetOnlineDisplayList"))
        XCTAssertTrue(source.contains("CGSConfigureDisplayEnabled"))
        XCTAssertTrue(source.contains("SLSConfigureDisplayEnabled"))
        XCTAssertTrue(source.contains("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight"))
        XCTAssertTrue(source.contains("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics"))
        XCTAssertTrue(source.contains("@convention(c) (CGDisplayConfigRef?, CGDirectDisplayID, Int32) -> CGError"))
        XCTAssertTrue(source.contains("CGDisplayIsBuiltin"))
        XCTAssertTrue(source.contains("No built-in display found for clamshell headless mode"))
        XCTAssertTrue(source.contains("configureDisplayEnabled(config, display.id, true)"))
        XCTAssertTrue(source.contains("configureDisplayEnabled(config, display.id, false)"))
        XCTAssertTrue(source.contains("displayEnabled(config, displayID, enabled ? 1 : 0)"))
        XCTAssertTrue(source.contains("try configureDisplayOrigin(config, virtualDisplayID, 0, 0)"))
        XCTAssertFalse(source.contains("try configureDisplayMirror(config, virtualDisplayID, kCGNullDirectDisplay)"))
        XCTAssertTrue(source.contains("try configureDisplayMode(config, display.id, display.mode)"))
    }
}

final class ClamshellMonitorTests: CaffeinatePlusTestCase {

    func testClamshellMessageParserUsesStateAndSleepBits() {
        XCTAssertEqual(
            ClamshellPowerMessage.parse(rawArgument: 0),
            ClamshellStateChange(stateBits: 0, isClosed: false, causesSleep: false)
        )
        XCTAssertEqual(
            ClamshellPowerMessage.parse(rawArgument: 1),
            ClamshellStateChange(stateBits: 1, isClosed: true, causesSleep: false)
        )
        XCTAssertEqual(
            ClamshellPowerMessage.parse(rawArgument: 3),
            ClamshellStateChange(stateBits: 3, isClosed: true, causesSleep: true)
        )
    }

    func testMonitorUsesSystemClamshellMessageAndArgumentBits() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: rootURL
                .appendingPathComponent("Sources")
                .appendingPathComponent("Services")
                .appendingPathComponent("ClamshellMonitor.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("stateChangeType: UInt32 = 0xE003_4100"))
        XCTAssertTrue(source.contains("kClamshellStateBit"))
        XCTAssertTrue(source.contains("kClamshellSleepBit"))
        XCTAssertTrue(source.contains("updateClamshellState(isClosed:"))
        XCTAssertFalse(source.contains("0xE000_0200"))
    }
}

final class ClamshellPowerManagementTests: CaffeinatePlusTestCase {

    func testPowerManagementUsesProcessLifetimeClamshellProtection() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: rootURL
                .appendingPathComponent("Sources")
                .appendingPathComponent("Services")
                .appendingPathComponent("ClamshellPowerManagement.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("activateAutomaticClamshellProtection"))
        XCTAssertTrue(source.contains("deactivateAutomaticClamshellProtection"))
        XCTAssertTrue(source.contains("automaticProtectionSnapshot"))
        XCTAssertTrue(source.contains("private var powerConnection"))
        XCTAssertTrue(source.contains("let connection = try openPowerManagementConnection()"))
        XCTAssertTrue(source.contains("try setClamshellSleepDisabled(true, connection: connection)"))
        XCTAssertTrue(source.contains("try setClamshellSleepDisabled(false, connection: powerConnection)"))
        XCTAssertTrue(source.contains("IOServiceClose(powerConnection)"))
        XCTAssertTrue(source.contains("kPMSetClamshellSleepStateSelector: UInt32 = 12"))
    }

    func testAppStatePreparesClamshellProtectionBeforeLidEvents() throws {
        let rootURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let source = try String(
            contentsOf: rootURL
                .appendingPathComponent("Sources")
                .appendingPathComponent("Services")
                .appendingPathComponent("AppState.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(source.contains("prepareAutomaticClamshellMode()"))
        XCTAssertTrue(source.contains("setupTerminationCallback()"))
        XCTAssertTrue(source.contains("NSApplication.willTerminateNotification"))
        XCTAssertTrue(source.contains("func shutdown()"))
        XCTAssertTrue(source.contains("clamshellPowerManagement.activateAutomaticClamshellProtection()"))
        XCTAssertTrue(source.contains("clamshellPowerManagement.deactivateAutomaticClamshellProtection()"))
        XCTAssertFalse(source.contains("power: clamshellPowerManagement"))
    }
}

private final class RecordingClamshellVirtualDisplay: ClamshellVirtualDisplayControlling {
    var isActive = false
    var displayID: UInt32 = 42
    var createdConfigs: [DisplayConfig] = []
    var removeCallCount = 0
    var onCreate: (() -> Void)?

    func createDisplay(config: DisplayConfig) throws {
        createdConfigs.append(config)
        isActive = true
        onCreate?()
    }

    func removeDisplay() {
        removeCallCount += 1
        isActive = false
    }
}

private final class RecordingClamshellSleep: ClamshellSleepControlling {
    var snapshot = ClamshellSleepSnapshot(
        preventDisplaySleep: false,
        preventSystemSleep: false,
        preventScreenSaver: false,
        preventAutoLock: false
    )
    var preventSleepCallCount = 0
    var restoredSnapshots: [ClamshellSleepSnapshot] = []
    var onPreventSleep: (() -> Void)?

    func preventSleep() throws {
        preventSleepCallCount += 1
        onPreventSleep?()
    }

    func restoreSleepState(_ snapshot: ClamshellSleepSnapshot) {
        restoredSnapshots.append(snapshot)
        self.snapshot = snapshot
    }
}

private final class RecordingClamshellDisplayConfiguration: ClamshellDisplayConfiguring {
    var snapshot = ClamshellDisplaySnapshot(displayIDs: [1, 2])
    var enteredVirtualDisplayIDs: [UInt32] = []
    var restoredSnapshots: [ClamshellDisplaySnapshot] = []
    var onCaptureDisplayConfiguration: (() -> Void)?
    var onEnterHeadlessMode: ((UInt32) -> Void)?
    var enterError: Error?

    func captureDisplayConfiguration() -> ClamshellDisplaySnapshot {
        onCaptureDisplayConfiguration?()
        return snapshot
    }

    func enterHeadlessMode(
        virtualDisplayID: UInt32,
        originalSnapshot: ClamshellDisplaySnapshot
    ) throws {
        enteredVirtualDisplayIDs.append(virtualDisplayID)
        onEnterHeadlessMode?(virtualDisplayID)
        if let enterError { throw enterError }
    }

    func restoreDisplayConfiguration(_ snapshot: ClamshellDisplaySnapshot) {
        restoredSnapshots.append(snapshot)
    }
}

private final class RecordingVirtualDisplayRuntime: VirtualDisplayRuntime {
    var isAvailable: Bool
    var createdSpecs: [VirtualDisplaySpec] = []
    var destroyedDisplayIDs: [UInt32] = []

    private var terminationHandler: (() -> Void)?

    init(isAvailable: Bool = true) {
        self.isAvailable = isAvailable
    }

    func createDisplay(
        spec: VirtualDisplaySpec,
        terminationHandler: @escaping () -> Void
    ) throws -> VirtualDisplayHandle {
        createdSpecs.append(spec)
        self.terminationHandler = terminationHandler
        return VirtualDisplayHandle(displayID: 42, displayObject: nil, terminationHandlerObject: nil)
    }

    func destroyDisplay(_ handle: VirtualDisplayHandle) {
        destroyedDisplayIDs.append(handle.displayID)
    }

    func fireTerminationHandler() {
        terminationHandler?()
    }
}

// MARK: - SystemMonitorService Tests

final class SystemMonitorServiceTests: CaffeinatePlusTestCase {

    var sut: SystemMonitorService!

    override func setUp() {
        super.setUp()
        sut = SystemMonitorService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testCPUUsage() {
        // When
        let cpuUsage = sut.cpuUsage

        // Then
        XCTAssertGreaterThanOrEqual(cpuUsage, 0.0)
        XCTAssertLessThanOrEqual(cpuUsage, 100.0)
    }

    func testMemoryUsage() {
        // When
        let memoryUsed = sut.memoryUsed
        let memoryTotal = sut.memoryTotal

        // Then
        XCTAssertGreaterThan(memoryUsed, 0)
        XCTAssertGreaterThan(memoryTotal, memoryUsed)
    }

    func testBatteryInfo() {
        // When
        let batteryLevel = sut.batteryLevel
        let isCharging = sut.isCharging

        // Then
        XCTAssertGreaterThanOrEqual(batteryLevel, -1) // -1 if no battery
        XCTAssertLessThanOrEqual(batteryLevel, 100)
        // isCharging is Bool, no assertion needed
        _ = isCharging
    }
}

// MARK: - DisplayConfig Tests

final class DisplayConfigTests: CaffeinatePlusTestCase {

    func testDisplayConfigLabel() {
        // Given
        let config = DisplayConfig(width: 1920, height: 1080, hiDPI: false, refreshRate: 60.0)

        // When
        let label = config.label

        // Then
        XCTAssertEqual(label, "1920×1080 @ 60Hz (Standard)")
    }

    func testHiDPILabel() {
        // Given
        let config = DisplayConfig(width: 2560, height: 1440, hiDPI: true, refreshRate: 60.0)

        // When
        let label = config.label

        // Then
        XCTAssertEqual(label, "2560×1440 @ 60Hz (HiDPI)")
    }

    func testAspectRatio() {
        // Given
        let config = DisplayConfig(width: 1920, height: 1080, hiDPI: false)

        // When
        let aspectRatio = config.aspectRatio

        // Then
        XCTAssertEqual(aspectRatio, 16.0/9.0, accuracy: 0.01)
    }
}

// MARK: - OperationMode Tests

final class OperationModeTests: CaffeinatePlusTestCase {

    func testOperationModeDescription() {
        let mode = OperationMode.virtualDisplay

        let description = mode.description

        XCTAssertFalse(description.isEmpty)
        XCTAssertNotEqual(description, "virtual_display_description")
    }

    func testOperationModeIcon() {
        // Given
        let mode = OperationMode.audioRouting

        // When
        let icon = mode.icon

        // Then
        XCTAssertFalse(icon.isEmpty)
    }
}

// MARK: - LicenseState Tests

final class LicenseStateTests: CaffeinatePlusTestCase {

    func testCanUseApp() {
        let activatedState = LicenseState.activated

        XCTAssertTrue(activatedState.canUseApp)
    }

    func testNeedsUpgrade() {
        let activatedState = LicenseState.activated

        XCTAssertFalse(activatedState.needsUpgrade)
    }

    func testDisplayText() {
        let activatedState = LicenseState.activated

        XCTAssertEqual(activatedState.displayText, "Open Source Edition")
    }
}

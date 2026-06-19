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

// MARK: - Clamshell Automation Tests

final class ClamshellAutomationTests: CaffeinatePlusTestCase {

    func testLidCloseCreatesVirtualDisplayAndPreventsSleep() throws {
        let automation = ClamshellAutomation()
        let virtualDisplay = RecordingClamshellVirtualDisplay()
        let sleep = RecordingClamshellSleep()
        let config = DisplayConfig(width: 1920, height: 1080, hiDPI: false)

        let shouldMarkActive = try automation.lidDidClose(
            config: config,
            wasAppActive: false,
            virtualDisplay: virtualDisplay,
            sleep: sleep
        )

        XCTAssertTrue(shouldMarkActive)
        XCTAssertEqual(virtualDisplay.createdConfigs, [config])
        XCTAssertEqual(sleep.preventSleepCallCount, 1)
    }

    func testLidOpenCleansOnlyAutoCreatedSession() throws {
        let automation = ClamshellAutomation()
        let virtualDisplay = RecordingClamshellVirtualDisplay()
        let sleep = RecordingClamshellSleep()

        _ = try automation.lidDidClose(
            config: DisplayConfig(width: 1920, height: 1080, hiDPI: false),
            wasAppActive: false,
            virtualDisplay: virtualDisplay,
            sleep: sleep
        )

        let shouldMarkActive = automation.lidDidOpen(
            virtualDisplay: virtualDisplay,
            sleep: sleep
        )

        XCTAssertEqual(shouldMarkActive, false)
        XCTAssertEqual(virtualDisplay.removeCallCount, 1)
        XCTAssertEqual(sleep.allowSleepCallCount, 1)
    }
}

private final class RecordingClamshellVirtualDisplay: ClamshellVirtualDisplayControlling {
    var isActive = false
    var createdConfigs: [DisplayConfig] = []
    var removeCallCount = 0

    func createDisplay(config: DisplayConfig) throws {
        createdConfigs.append(config)
        isActive = true
    }

    func removeDisplay() {
        removeCallCount += 1
        isActive = false
    }
}

private final class RecordingClamshellSleep: ClamshellSleepControlling {
    var preventSleepCallCount = 0
    var allowSleepCallCount = 0

    func preventSleep() throws {
        preventSleepCallCount += 1
    }

    func allowSleep() {
        allowSleepCallCount += 1
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

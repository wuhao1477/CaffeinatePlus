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

    override func setUp() {
        super.setUp()
        sut = VirtualDisplayService()
    }

    override func tearDown() {
        sut.removeDisplay()
        sut = nil
        super.tearDown()
    }

    func testAPIAvailability() {
        XCTAssertEqual(sut.isAPIAvailable, sut.isAPIAvailable)
    }

    @available(macOS 13.0, *)
    func testCreateDisplayReportsUnavailableInsteadOfPretendingSuccess() throws {
        let config = DisplayConfig(width: 1920, height: 1080, hiDPI: false)

        do {
            try sut.createDisplay(config: config)
            XCTAssertTrue(sut.isActive)
        } catch {
            XCTAssertFalse(sut.isActive)
            XCTAssertNotNil(error.localizedDescription)
        }
    }

    @available(macOS 13.0, *)
    func testRemoveDisplay() throws {
        sut.removeDisplay()

        XCTAssertFalse(sut.isActive)
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

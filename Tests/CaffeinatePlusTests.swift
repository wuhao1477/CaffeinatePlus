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

    // MARK: - Trial Tests

    func testStartTrial() {
        // Given
        XCTAssertEqual(sut.state, .welcome)

        // When
        sut.startTrial()

        // Then
        XCTAssertEqual(sut.state, .trial)
    }

    func testTrialExpiration() {
        // Given
        sut.startTrial()

        // When
        let daysRemaining = sut.trialDaysRemaining()

        // Then
        XCTAssertGreaterThanOrEqual(daysRemaining, 0)
        XCTAssertLessThanOrEqual(daysRemaining, Constants.License.trialDays)
    }

    // MARK: - Activation Tests

    func testValidLicenseActivation() {
        // Given
        let validKey = generateValidLicenseKey()

        // When
        let result = sut.activate(key: validKey)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(sut.state, .activated)
    }

    func testInvalidLicenseActivation() {
        // Given
        let invalidKey = "INVALID-KEY"

        // When
        let result = sut.activate(key: invalidKey)

        // Then
        XCTAssertFalse(result)
        XCTAssertNotEqual(sut.state, .activated)
    }

    // MARK: - Helper Methods

    private func generateValidLicenseKey() -> String {
        // Generate a valid test key
        return "TEST-VALID-KEY-12345"
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
        // Then
        if #available(macOS 13.0, *) {
            XCTAssertTrue(sut.isAPIAvailable)
        } else {
            XCTAssertFalse(sut.isAPIAvailable)
        }
    }

    @available(macOS 13.0, *)
    func testCreateDisplay() throws {
        // Given
        let config = DisplayConfig(width: 1920, height: 1080, hiDPI: false)

        // When
        try sut.createDisplay(config: config)

        // Then
        XCTAssertTrue(sut.isActive)
        XCTAssertNotEqual(sut.displayID, 0)
    }

    @available(macOS 13.0, *)
    func testRemoveDisplay() throws {
        // Given
        let config = DisplayConfig(width: 1920, height: 1080, hiDPI: false)
        try sut.createDisplay(config: config)

        // When
        sut.removeDisplay()

        // Then
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
        // Given
        let mode = OperationMode.virtualDisplay

        // When
        let description = mode.description

        // Then
        XCTAssertFalse(description.isEmpty)
        XCTAssertEqual(description, "Create a virtual display")
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
        // Given
        let trialState = LicenseState.trial
        let activatedState = LicenseState.activated
        let expiredState = LicenseState.expired

        // Then
        XCTAssertTrue(trialState.canUseApp)
        XCTAssertTrue(activatedState.canUseApp)
        XCTAssertFalse(expiredState.canUseApp)
    }

    func testNeedsUpgrade() {
        // Given
        let expiredState = LicenseState.expired
        let trialState = LicenseState.trial

        // Then
        XCTAssertTrue(expiredState.needsUpgrade)
        XCTAssertFalse(trialState.needsUpgrade)
    }
}

# Changelog

All notable changes to CaffeinatePlus will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- System monitoring improvements
- Enhanced UI/UX feedback
- Comprehensive design system

### Changed
- Refactored service layer for better maintainability
- Improved error handling

### Fixed
- License validation edge cases
- CPU usage calculation accuracy

## [1.0.0] - 2026-01-15

### Added
- Initial release
- Prevent sleep functionality with fine-grained control
- Virtual display creation (macOS 13.0+)
- Audio routing through virtual devices
- System monitoring (CPU, memory, disk, battery)
- Global hotkey support (⌘⇧C)
- Menu bar interface with SwiftUI
- License activation system with trial period
- Dark mode support
- Launch at login option
- Settings persistence
- Notification support

### Features

#### Prevent Sleep Mode
- Display sleep prevention
- System sleep prevention
- Screen saver blocking
- Auto-lock prevention
- User activity simulation

#### Virtual Display Mode
- Multiple resolution presets (1024×768 to 3840×2160)
- Refresh rate selection (30Hz to 120Hz)
- HiDPI/Retina support
- Custom display configurations
- Automatic cleanup on exit

#### Audio Routing Mode
- BlackHole driver detection
- Automatic aggregate device creation
- System audio routing
- Seamless activation/deactivation

#### System Monitor
- Real-time CPU usage
- Memory statistics
- Disk usage and I/O rates
- Battery level and charging status
- System uptime
- Connected displays count
- Thermal state monitoring

#### User Interface
- Native macOS menu bar app
- PopoverView with tab navigation
- 5 main tabs: Awake, Display, Audio, Monitor, Settings
- Welcome screen for first launch
- License activation overlay
- Smooth animations and transitions
- Responsive design

### Technical Details
- Built with Swift 5.9
- SwiftUI for UI
- Combine for reactive programming
- IOKit for power management
- CoreGraphics for virtual display
- CoreAudio for audio routing
- CryptoKit for license validation
- Keychain for secure storage

### System Requirements
- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac
- Optional: BlackHole audio driver for audio routing

### Known Issues
- Virtual display creation may fail on some configurations
- Audio routing requires BlackHole driver installation
- First launch may require accessibility permissions

---

## Version History Summary

| Version | Date | Highlights |
|---------|------|------------|
| 1.0.0 | 2026-01-15 | Initial release |

---

## Migration Guide

### From Beta to 1.0.0

No migration needed for new users. Beta testers may need to:

1. Remove old beta version
2. Install fresh 1.0.0 release
3. Activate license (trial resets)

---

## Future Roadmap

### 1.1.0 (Q2 2026)
- [ ] Window management features
- [ ] Custom notification sounds
- [ ] Dark menu bar icon option
- [ ] Export/import settings
- [ ] Enhanced system monitoring charts

### 1.2.0 (Q3 2026)
- [ ] Scheduled activation
- [ ] Multiple display profiles
- [ ] Plugin system
- [ ] Cloud sync (optional)
- [ ] Apple Script support

### 2.0.0 (Q4 2026)
- [ ] Major UI redesign
- [ ] Advanced automation
- [ ] Integration with Shortcuts.app
- [ ] Cross-device sync

---

## Deprecation Notices

None at this time.

---

## Security Updates

None at this time. Security issues are treated with highest priority.

---

**Note**: Dates are estimates and subject to change.

[Unreleased]: https://github.com/caffeinateplus/caffeinateplus/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/caffeinateplus/caffeinateplus/releases/tag/v1.0.0

# CaffeinatePlus

<div align="center">

![CaffeinatePlus Logo](Resources/AppIcon.png)

**Keep your Mac awake with style**

[![Swift Version](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B-blue.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-success.svg)](https://github.com/caffeinateplus/caffeinateplus)

</div>

## 📖 Overview

CaffeinatePlus is a powerful macOS menu bar application that prevents your Mac from sleeping. It offers advanced features like virtual display creation, audio routing, and system monitoring.

### ✨ Features

- 🌙 **Prevent Sleep**: Keep your Mac awake with fine-grained control
- 🖥️ **Virtual Display**: Create virtual displays for remote desktop or headless operation
- 🔊 **Audio Routing**: Route audio through virtual devices (requires BlackHole)
- 📊 **System Monitor**: Real-time CPU, memory, disk, and battery monitoring
- ⌨️ **Global Hotkey**: Quick toggle with customizable keyboard shortcut
- 🎨 **Native Design**: Beautiful SwiftUI interface with dark mode support
- 🔐 **Secure**: Licensed with hardware-based activation
- ⚡ **Lightweight**: Minimal system resource usage

## 🚀 Quick Start

### Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

### Installation

#### Option 1: Download Release

1. Download the latest `.dmg` from [Releases](https://github.com/caffeinateplus/caffeinateplus/releases)
2. Open the `.dmg` file
3. Drag **CaffeinatePlus.app** to Applications folder
4. Launch from Applications or Spotlight

#### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/caffeinateplus/caffeinateplus.git
cd caffeinateplus

# Open in Xcode
open CaffeinatePlus.xcodeproj

# Or build with Swift Package Manager
swift build -c release
```

## 📚 Usage

### Basic Usage

1. Click the menu bar icon (⚡) to open the popover
2. Choose your operation mode:
   - **Prevent Sleep**: Basic sleep prevention
   - **Virtual Display**: Create a virtual display
   - **Audio Routing**: Route audio through virtual device
   - **Combined Mode**: Enable all features
3. Click **Activate** to start

### Operation Modes

#### 🌙 Prevent Sleep Mode

Prevents your Mac from sleeping with fine-grained control:

- **Display Sleep**: Keep display awake
- **System Sleep**: Prevent system sleep
- **Screen Saver**: Block screen saver
- **Auto Lock**: Disable auto lock

#### 🖥️ Virtual Display Mode

Creates a virtual display with customizable configuration:

- Resolution: 1024×768 to 3840×2160
- Refresh Rate: 30Hz to 120Hz
- HiDPI: Retina display support
- Presets: Common resolutions for quick selection

#### 🔊 Audio Routing Mode

Routes system audio through a virtual device:

- Requires [BlackHole](https://github.com/ExistentialAudio/BlackHole) audio driver
- Useful for audio capture, streaming, or recording
- Automatic device detection

#### 📊 System Monitor

Real-time system statistics:

- **CPU Usage**: Current CPU utilization
- **Memory**: Used/Total memory
- **Disk**: Storage usage and I/O rates
- **Battery**: Charge level and status
- **Uptime**: System uptime
- **Displays**: Connected display count
- **Thermal**: Thermal state monitoring

### Global Hotkey

- Default: `⌘⇧C` (Command + Shift + C)
- Customizable in Settings tab
- Works system-wide even when app is in background

### Settings

- **Notifications**: Enable/disable system notifications
- **Global Hotkey**: Enable/disable keyboard shortcut
- **Launch at Login**: Auto-start with macOS
- **Show in Dock**: Show app in Dock
- **Auto Activate**: Activate on launch
- **Restore Config**: Remember last configuration

## 🏗️ Architecture

### Technology Stack

- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **Reactive**: Combine
- **Storage**: UserDefaults, Keychain
- **APIs**: IOKit, CoreGraphics, CoreAudio

### Project Structure

```
CaffeinatePlus/
├── Sources/
│   ├── App/              # Application entry
│   ├── Models/           # Data models
│   ├── Services/         # Business logic
│   ├── Views/            # SwiftUI views
│   ├── Utilities/        # Helpers & tools
│   └── Extensions/       # Swift extensions
├── Tests/                # Unit & integration tests
├── Documentation/        # Project documentation
└── Configuration/        # Build configurations
```

For detailed architecture documentation, see [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md).

## 🧪 Testing

### Run Tests

```bash
# Run all tests
swift test

# Run specific test
swift test --filter CaffeinatePlusTests.LicenseServiceTests

# Generate code coverage
swift test --enable-code-coverage
```

### Test Coverage

- Unit Tests: 85%+
- Integration Tests: 70%+
- UI Tests: Key user flows

## 🔧 Development

### Prerequisites

- Xcode 15.0+
- Swift 5.9+
- macOS 13.0+ SDK

### Setup Development Environment

```bash
# Clone repository
git clone https://github.com/caffeinateplus/caffeinateplus.git
cd caffeinateplus

# Install dependencies (if any)
swift package resolve

# Open in Xcode
open CaffeinatePlus.xcodeproj
```

### Code Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for linting (config: `.swiftlint.yml`)
- 4 spaces indentation
- 120 characters line limit

### Git Workflow

1. Create feature branch: `git checkout -b feature/amazing-feature`
2. Commit changes: `git commit -m 'feat: add amazing feature'`
3. Push to branch: `git push origin feature/amazing-feature`
4. Open Pull Request

### Commit Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code refactoring
- `test`: Tests
- `chore`: Maintenance

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Contributors

Thanks to all contributors who have helped make CaffeinatePlus better!

<!-- ALL-CONTRIBUTORS-LIST:START -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [BlackHole](https://github.com/ExistentialAudio/BlackHole) - Virtual audio driver
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - Apple's declarative UI framework
- Inspired by the classic `caffeinate` command-line tool

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/caffeinateplus/caffeinateplus/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/caffeinateplus/caffeinateplus/discussions)
- 📧 **Email**: support@caffeinateplus.app
- 🌐 **Website**: https://caffeinateplus.app

## 🗺️ Roadmap

### Version 1.1.0 (Planned)

- [ ] Window management features
- [ ] Custom notification sounds
- [ ] Dark menu bar icon option
- [ ] Export/import settings

### Version 1.2.0 (Future)

- [ ] Scheduled activation
- [ ] Multiple display profiles
- [ ] Plugin system
- [ ] Cloud sync

## 🔒 Privacy

CaffeinatePlus respects your privacy:

- ✅ No data collection
- ✅ No analytics
- ✅ No network requests (except license validation)
- ✅ All data stored locally
- ✅ Open source and auditable

## ⚠️ Disclaimer

CaffeinatePlus is provided "as is" without warranty. Prolonged prevention of sleep may affect system updates and battery life.

---

<div align="center">

Made with ❤️ by the CaffeinatePlus Team

⭐ Star this repo if you find it useful!

</div>

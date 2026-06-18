# Contributing to CaffeinatePlus

First off, thank you for considering contributing to CaffeinatePlus! 🎉

The following is a set of guidelines for contributing to CaffeinatePlus. These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Issue Guidelines](#issue-guidelines)

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to conduct@caffeinateplus.app.

### Our Pledge

- Be respectful and inclusive
- Welcome newcomers
- Accept constructive criticism
- Focus on what's best for the community

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

**How to submit a good bug report:**

1. **Use a clear and descriptive title**
2. **Describe the exact steps to reproduce**
3. **Provide specific examples**
4. **Describe the behavior you observed and expected**
5. **Include screenshots if applicable**
6. **Specify your environment** (macOS version, CaffeinatePlus version)

**Bug Report Template:**

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
 - macOS Version: [e.g. 13.4]
 - CaffeinatePlus Version: [e.g. 1.0.0]
 - Mac Model: [e.g. MacBook Pro M2]

**Additional context**
Any other context about the problem.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues.

**How to submit a good enhancement suggestion:**

1. **Use a clear and descriptive title**
2. **Provide a detailed description**
3. **Explain why this enhancement would be useful**
4. **List similar features in other apps if applicable**

**Enhancement Template:**

```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Any alternative solutions or features.

**Additional context**
Any other context or screenshots.
```

### Pull Requests

We actively welcome your pull requests!

1. Fork the repo and create your branch from `develop`
2. If you've added code, add tests
3. Ensure the test suite passes
4. Make sure your code lints
5. Issue the pull request

## Development Setup

### Prerequisites

- Xcode 15.0+
- Swift 5.9+
- macOS 13.0+ (for testing)

### Setup Instructions

```bash
# 1. Fork and clone
git clone https://github.com/YOUR_USERNAME/caffeinateplus.git
cd caffeinateplus

# 2. Create a branch
git checkout -b feature/amazing-feature

# 3. Install dependencies
swift package resolve

# 4. Open in Xcode
open CaffeinatePlus.xcodeproj

# 5. Build and run
⌘R in Xcode
```

### Project Structure

```
CaffeinatePlus/
├── Sources/
│   ├── App/              # Application entry point
│   ├── Models/           # Data models
│   ├── Services/         # Business logic
│   ├── Views/            # SwiftUI views
│   ├── Utilities/        # Helper utilities
│   └── Extensions/       # Swift extensions
├── Tests/                # Test files
└── Documentation/        # Documentation
```

## Coding Guidelines

### Swift Style Guide

Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

#### Key Points

1. **Naming**
   - Use clear, descriptive names
   - Types: `UpperCamelCase`
   - Functions/variables: `lowerCamelCase`
   - Constants: `lowerCamelCase` or `UPPER_SNAKE_CASE`

2. **Formatting**
   - 4 spaces for indentation (no tabs)
   - 120 characters max line length
   - One statement per line
   - Opening braces on same line

3. **Code Organization**
   - Use `// MARK: -` to organize code
   - Group related functionality
   - Keep files focused and small

4. **Documentation**
   - Document all public APIs
   - Use Swift's documentation format
   - Include examples for complex functionality

Example:

```swift
/// Prevents the Mac from sleeping
///
/// This method creates power assertions to prevent various
/// types of sleep states.
///
/// - Throws: `CaffeinateError` if prevention fails
/// - Note: Call `allowSleep()` to release assertions
func preventSleep() throws {
    // Implementation
}
```

### SwiftUI Best Practices

1. **View Decomposition**
   - Keep views small and focused
   - Extract subviews for reusability
   - Use `@ViewBuilder` for conditional content

2. **State Management**
   - Use `@State` for view-local state
   - Use `@StateObject` for owned objects
   - Use `@ObservedObject` for shared state
   - Use `@EnvironmentObject` for app-wide state

3. **Performance**
   - Avoid heavy computation in body
   - Use `@Binding` to avoid copies
   - Optimize list rendering

### Testing

1. **Unit Tests**
   - Test all public methods
   - Mock dependencies
   - Aim for 80%+ coverage

2. **Integration Tests**
   - Test service interactions
   - Verify data flow
   - Test error handling

3. **UI Tests**
   - Test critical user flows
   - Verify UI state changes
   - Test accessibility

Example test:

```swift
func testPreventSleep() throws {
    let service = SleepService()
    
    try service.preventSleep()
    
    XCTAssertTrue(service.isPreventingAnything)
}
```

## Commit Guidelines

We use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting (no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvement
- `test`: Adding tests
- `chore`: Build/tooling changes

### Examples

```bash
feat(sleep): add screen saver prevention

Implements screen saver blocking using IOKit APIs.
Adds new preventScreenSaver property to SleepService.

Closes #123
```

```bash
fix(license): correct trial expiration calculation

Trial period was calculating incorrectly due to timezone
issues. Now uses UTC for all date calculations.

Fixes #456
```

### Rules

- Use present tense ("add" not "added")
- Use imperative mood ("move" not "moves")
- First line max 72 characters
- Reference issues in footer

## Pull Request Process

### Before Submitting

1. ✅ Update documentation
2. ✅ Add/update tests
3. ✅ Run all tests locally
4. ✅ Update CHANGELOG.md
5. ✅ Check code formatting
6. ✅ Squash commits if needed

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
Describe testing performed

## Screenshots
If UI changes, include screenshots

## Checklist
- [ ] My code follows project style
- [ ] I've added tests
- [ ] All tests pass
- [ ] I've updated documentation
- [ ] I've updated CHANGELOG
```

### Review Process

1. At least one maintainer must approve
2. All CI checks must pass
3. No unresolved conversations
4. Up to date with base branch

### After Merge

- Delete your branch
- Update local repository
- Celebrate! 🎉

## Issue Guidelines

### Issue Labels

- `bug`: Something isn't working
- `enhancement`: New feature or request
- `documentation`: Documentation improvements
- `good first issue`: Good for newcomers
- `help wanted`: Extra attention needed
- `question`: Further information requested
- `wontfix`: Won't be addressed
- `duplicate`: Already reported

### Issue Lifecycle

1. **Open**: Issue reported
2. **Triaged**: Reviewed by maintainers
3. **In Progress**: Being worked on
4. **Review**: PR under review
5. **Closed**: Completed or resolved

## Getting Help

- 💬 **GitHub Discussions**: Ask questions
- 📧 **Email**: dev@caffeinateplus.app
- 📖 **Documentation**: Check the docs first

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in the app (if significant contribution)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to CaffeinatePlus! 🙏

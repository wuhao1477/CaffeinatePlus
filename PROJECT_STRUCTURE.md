# CaffeinatePlus Project Structure

## 项目架构

```
CaffeinatePlus/
├── Package.swift                 # Swift Package Manager 配置
├── README.md                     # 项目说明
├── CHANGELOG.md                  # 版本变更日志
├── LICENSE                       # 开源协议
│
├── Sources/                      # 源代码目录
│   ├── App/                      # 应用入口
│   │   └── CaffeinatePlusApp.swift
│   │
│   ├── Models/                   # 数据模型
│   │   ├── DisplayConfig.swift
│   │   ├── OperationMode.swift
│   │   └── LicenseState.swift
│   │
│   ├── Services/                 # 业务服务层
│   │   ├── AppState.swift
│   │   ├── LicenseService.swift
│   │   ├── SleepService.swift
│   │   ├── VirtualDisplayService.swift
│   │   ├── SystemMonitorService.swift
│   │   ├── HotkeyService.swift
│   │   ├── AudioService.swift
│   │   ├── ClamshellMonitor.swift
│   │   └── NotificationService.swift
│   │
│   ├── Views/                    # 视图层
│   │   ├── Views.swift
│   │   ├── PopoverView.swift
│   │   ├── TabViews/
│   │   └── Components/
│   │
│   ├── ViewModels/               # 视图模型（如需要）
│   │
│   ├── Utilities/                # 工具类
│   │   ├── DesignSystem.swift
│   │   ├── FeedbackComponents.swift
│   │   ├── MissingPieces.swift
│   │   └── Logger.swift
│   │
│   ├── Extensions/               # 扩展
│   │   └── Extensions.swift
│   │
│   └── Resources/                # 资源文件
│       ├── Assets.xcassets
│       └── Info.plist
│
├── Tests/                        # 测试目录
│   ├── UnitTests/
│   ├── IntegrationTests/
│   └── UITests/
│
├── Documentation/                # 文档目录
│   ├── README.md
│   ├── Architecture.md
│   ├── API.md
│   └── UserGuide.md
│
└── Configuration/                # 配置文件
    ├── Debug.xcconfig
    ├── Release.xcconfig
    └── Secrets.xcconfig.template
```

## 架构设计

### 分层架构

1. **App Layer (应用层)**
   - 应用入口点
   - 生命周期管理

2. **View Layer (视图层)**
   - SwiftUI 视图
   - UI 组件
   - 用户交互

3. **ViewModel Layer (视图模型层)**
   - 视图状态管理
   - 业务逻辑适配

4. **Service Layer (服务层)**
   - 业务逻辑实现
   - 系统 API 封装
   - 状态管理

5. **Model Layer (模型层)**
   - 数据结构定义
   - 业务实体

6. **Utility Layer (工具层)**
   - 通用工具
   - 扩展方法
   - 常量定义

### 设计模式

- **MVVM**: Model-View-ViewModel 架构
- **Observable**: Combine 响应式编程
- **Singleton**: 单例服务（Logger, NotificationService）
- **Dependency Injection**: 依赖注入（通过 @EnvironmentObject）
- **Factory**: 工厂模式（服务创建）
- **Strategy**: 策略模式（不同的防睡眠策略）

### 依赖关系

```
App
 └─> Views
      └─> Services
           └─> Models
                └─> Utilities
```

## 代码规范

### 文件组织

- 每个文件只包含一个主要类型
- 按功能模块组织文件
- 使用 `// MARK: -` 分隔代码段

### 命名规范

- **类/结构体/枚举**: UpperCamelCase
- **方法/变量**: lowerCamelCase
- **常量**: UPPER_SNAKE_CASE 或 lowerCamelCase
- **协议**: 以 -able/-ing 结尾或描述性名词

### 代码风格

- 使用 4 空格缩进
- 每行最大 120 字符
- 避免强制解包 `!`
- 优先使用 `guard let` 而非 `if let`
- 使用 `// TODO:` 和 `// FIXME:` 标记

### 注释规范

```swift
/// 简短描述（单行）
///
/// 详细描述（多行）
/// 说明功能、使用方法、注意事项
///
/// - Parameters:
///   - param1: 参数1说明
///   - param2: 参数2说明
/// - Returns: 返回值说明
/// - Throws: 可能抛出的错误
func exampleMethod(param1: String, param2: Int) throws -> Bool {
    // 实现
}
```

## 构建配置

### Debug 配置

- 启用调试日志
- 显示调试信息
- 不混淆代码

### Release 配置

- 优化编译
- 移除调试符号
- 代码混淆（如需要）

### 环境变量

```swift
// 使用编译标志区分环境
#if DEBUG
let apiEndpoint = "https://dev.api.example.com"
#else
let apiEndpoint = "https://api.example.com"
#endif
```

## 测试策略

### 单元测试

- 测试覆盖率目标：80%+
- 测试所有公开方法
- 使用 Mock 对象隔离依赖

### 集成测试

- 测试服务间交互
- 测试系统 API 调用
- 验证数据流

### UI 测试

- 测试关键用户流程
- 验证 UI 状态
- 截图对比

## 版本管理

### Git 工作流

- `main`: 主分支，稳定版本
- `develop`: 开发分支
- `feature/*`: 功能分支
- `bugfix/*`: 修复分支
- `release/*`: 发布分支

### Commit 规范

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Type**:
- `feat`: 新功能
- `fix`: 修复
- `docs`: 文档
- `style`: 格式
- `refactor`: 重构
- `test`: 测试
- `chore`: 构建/工具

### 版本号

遵循 [Semantic Versioning](https://semver.org/)：

- `MAJOR.MINOR.PATCH`
- `1.0.0`: 初始版本
- `1.1.0`: 新增功能
- `1.1.1`: Bug 修复

## 发布流程

1. 代码审查
2. 运行所有测试
3. 更新版本号
4. 更新 CHANGELOG
5. 创建 Git Tag
6. 构建 Release 版本
7. 代码签名
8. 公证（Notarization）
9. 发布到 GitHub Releases
10. 更新文档

## 持续集成/持续部署 (CI/CD)

### GitHub Actions 工作流

- **Push**: 运行测试
- **Pull Request**: 代码审查、测试
- **Tag**: 构建发布版本

### 自动化任务

- 代码格式检查
- 静态分析
- 单元测试
- 集成测试
- 构建验证

## 性能优化

### 编译时优化

- 使用 Whole Module Optimization
- 启用 Link-Time Optimization (LTO)

### 运行时优化

- 延迟加载
- 缓存策略
- 异步处理
- 内存管理

## 安全考虑

### 代码安全

- 不在代码中硬编码密钥
- 使用 Keychain 存储敏感信息
- 输入验证
- 错误处理不泄露敏感信息

### 系统安全

- 最小权限原则
- 沙盒化
- 代码签名
- Hardened Runtime

## 维护指南

### 日常维护

- 定期更新依赖
- 修复已知问题
- 优化性能
- 更新文档

### 技术债务管理

- 定期重构
- 代码审查
- 技术选型评估

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交变更
4. 推送到分支
5. 创建 Pull Request

## 联系方式

- **Issue Tracker**: GitHub Issues
- **讨论**: GitHub Discussions
- **邮件**: support@caffeinateplus.app

---

**最后更新**: 2026-06-18
**维护者**: CaffeinatePlus Team

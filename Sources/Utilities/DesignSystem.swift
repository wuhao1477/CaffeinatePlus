// DesignSystem.swift
// CaffeinatePlus 设计系统
// 统一颜色、字体、间距、动画

import SwiftUI

// MARK: - Color System

extension Color {

    // MARK: Brand Colors

    /// 主品牌色
    static let caffeinatePrimary = Color(hex: "#FF6B35")

    /// 次要品牌色
    static let caffeinateSecondary = Color(hex: "#4ECDC4")

    /// 强调色
    static let caffeinateAccent = Color.accentColor

    // MARK: Status Colors

    /// 激活状态
    static let caffeinateActive = Color.green

    /// 未激活状态
    static let caffeinateInactive = Color.gray

    /// 错误状态
    static let caffeinateError = Color.red

    /// 警告状态
    static let caffeinateWarning = Color.orange

    /// 信息状态
    static let caffeinateInfo = Color.blue

    /// 成功状态
    static let caffeinateSuccess = Color.green

    // MARK: Background Colors

    /// 卡片背景
    static let caffeinateCardBackground = Color(
        light: Color(white: 0.95),
        dark: Color(white: 0.15)
    )

    /// 次要背景
    static let caffeinateSecondaryBackground = Color(
        light: Color(white: 0.98),
        dark: Color(white: 0.1)
    )

    /// 分割线颜色
    static let caffeinateDivider = Color(
        light: Color(white: 0.9),
        dark: Color(white: 0.2)
    )

    // MARK: Text Colors

    /// 主要文本
    static let caffeinatePrimaryText = Color.primary

    /// 次要文本
    static let caffeinateSecondaryText = Color.secondary

    /// 占位符文本
    static let caffeinatePlaceholder = Color.gray.opacity(0.6)

    // MARK: Helper Initializer

    init(light: Color, dark: Color) {
        #if os(macOS)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.name == .darkAqua ? NSColor(dark) : NSColor(light)
        })
        #else
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #endif
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Font System

extension Font {

    /// 大标题 - 24pt, Bold
    static let caffeinateLargeTitle = Font.system(size: 24, weight: .bold)

    /// 标题 - 18pt, Semibold
    static let caffeinateTitle = Font.system(size: 18, weight: .semibold)

    /// 标题2 - 16pt, Semibold
    static let caffeinateTitle2 = Font.system(size: 16, weight: .semibold)

    /// 正文 - 14pt, Regular
    static let caffeinateBody = Font.system(size: 14, weight: .regular)

    /// 正文粗体 - 14pt, Medium
    static let caffeinateBodyBold = Font.system(size: 14, weight: .medium)

    /// 小标题 - 13pt, Regular
    static let caffeinateCallout = Font.system(size: 13, weight: .regular)

    /// 说明文字 - 12pt, Regular
    static let caffeinateCaption = Font.system(size: 12, weight: .regular)

    /// 小说明文字 - 11pt, Regular
    static let caffeinateCaption2 = Font.system(size: 11, weight: .regular)

    /// 单行代码 - 13pt, Monospaced
    static let caffeinateCode = Font.system(size: 13, design: .monospaced)
}

// MARK: - Spacing System

extension CGFloat {

    /// 超小间距 - 4pt
    static let caffeinateSpacingXS: CGFloat = 4

    /// 小间距 - 8pt
    static let caffeinateSpacingS: CGFloat = 8

    /// 中等间距 - 12pt
    static let caffeinateSpacingM: CGFloat = 12

    /// 大间距 - 16pt
    static let caffeinateSpacingL: CGFloat = 16

    /// 超大间距 - 24pt
    static let caffeinateSpacingXL: CGFloat = 24

    /// 巨大间距 - 32pt
    static let caffeinateSpacingXXL: CGFloat = 32
}

// MARK: - Corner Radius

extension CGFloat {

    /// 小圆角 - 4pt
    static let caffeinateCornerRadiusS: CGFloat = 4

    /// 中等圆角 - 8pt
    static let caffeinateCornerRadiusM: CGFloat = 8

    /// 大圆角 - 12pt
    static let caffeinateCornerRadiusL: CGFloat = 12

    /// 超大圆角 - 16pt
    static let caffeinateCornerRadiusXL: CGFloat = 16
}

// MARK: - Animation System

extension Animation {

    /// 标准弹簧动画
    static let caffeinateSpring = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7
    )

    /// 快速弹簧动画
    static let caffeinateSpringFast = Animation.spring(
        response: 0.2,
        dampingFraction: 0.8
    )

    /// 标准缓动动画
    static let caffeinateEaseInOut = Animation.easeInOut(duration: 0.3)

    /// 快速缓动动画
    static let caffeinateEaseInOutFast = Animation.easeInOut(duration: 0.2)

    /// 慢速缓动动画
    static let caffeinateEaseInOutSlow = Animation.easeInOut(duration: 0.5)
}

// MARK: - Shadow System

extension View {

    /// 卡片阴影
    func caffeinateCardShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 2
        )
    }

    /// 浮动阴影
    func caffeinateElevatedShadow() -> some View {
        self.shadow(
            color: Color.black.opacity(0.15),
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Common Modifiers

extension View {

    /// 标准卡片样式
    func caffeinateCard() -> some View {
        self
            .padding(.caffeinateSpacingL)
            .background(Color.caffeinateCardBackground)
            .cornerRadius(.caffeinateCornerRadiusL)
            .caffeinateCardShadow()
    }

    /// 标准按钮样式
    func caffeinatePrimaryButton() -> some View {
        self
            .font(.caffeinateBodyBold)
            .foregroundColor(.white)
            .padding(.horizontal, .caffeinateSpacingL)
            .padding(.vertical, .caffeinateSpacingS)
            .background(Color.accentColor)
            .cornerRadius(.caffeinateCornerRadiusM)
    }

    /// 次要按钮样式
    func caffeinateSecondaryButton() -> some View {
        self
            .font(.caffeinateBody)
            .foregroundColor(.caffeinatePrimaryText)
            .padding(.horizontal, .caffeinateSpacingL)
            .padding(.vertical, .caffeinateSpacingS)
            .background(Color.caffeinateCardBackground)
            .cornerRadius(.caffeinateCornerRadiusM)
    }
}

// MARK: - Icon System

enum CaffeinateIcon {

    // Tab Icons
    static let awake = "moon.zzz"
    static let display = "display"
    static let audio = "speaker.wave.2"
    static let monitor = "chart.bar"
    static let settings = "gear"

    // Status Icons
    static let active = "bolt.fill"
    static let inactive = "bolt"
    static let success = "checkmark.circle.fill"
    static let error = "exclamationmark.triangle.fill"
    static let warning = "exclamationmark.circle.fill"
    static let info = "info.circle.fill"

    // Action Icons
    static let close = "xmark"
    static let refresh = "arrow.clockwise"
    static let download = "arrow.down.circle"
    static let upload = "arrow.up.circle"
}

// MARK: - Accessibility Helpers

extension View {

    /// 添加标准的可访问性标签
    func caffeinateAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .modifier(CaffeinateAccessibilityModifier(
                hint: hint,
                value: value,
                traits: traits
            ))
    }
}

struct CaffeinateAccessibilityModifier: ViewModifier {
    let hint: String?
    let value: String?
    let traits: AccessibilityTraits

    func body(content: Content) -> some View {
        var modified = content.asAnyView()

        if let hint = hint {
            modified = modified.accessibilityHint(hint).asAnyView()
        }

        if let value = value {
            modified = modified.accessibilityValue(value).asAnyView()
        }

        if !traits.isEmpty {
            modified = modified.accessibilityAddTraits(traits).asAnyView()
        }

        return modified
    }
}

extension View {
    func asAnyView() -> AnyView {
        AnyView(self)
    }
}

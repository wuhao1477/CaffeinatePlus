// Extensions.swift
// SwiftUI 和 Foundation 扩展

import SwiftUI

// MARK: - View Extensions

extension View {
  /// 条件修饰符
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

// 注意: Color.init(hex:) 已在 DesignSystem.swift 中定义，避免重复

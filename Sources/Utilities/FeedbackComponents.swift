// FeedbackComponents.swift
// 状态反馈组件：Toast、Alert、Loading
// 对齐原始应用的用户反馈机制

import SwiftUI

// MARK: - Toast Notification

/// Toast 通知视图
struct ToastView: View {
    let message: String
    let icon: String
    let type: ToastType

    enum ToastType {
        case success, error, warning, info

        var color: Color {
            switch self {
            case .success: return .caffeinateSuccess
            case .error: return .caffeinateError
            case .warning: return .caffeinateWarning
            case .info: return .caffeinateInfo
            }
        }

        var defaultIcon: String {
            switch self {
            case .success: return CaffeinateIcon.success
            case .error: return CaffeinateIcon.error
            case .warning: return CaffeinateIcon.warning
            case .info: return CaffeinateIcon.info
            }
        }
    }

    var body: some View {
        HStack(spacing: .caffeinateSpacingM) {
            Image(systemName: icon.isEmpty ? type.defaultIcon : icon)
                .foregroundColor(type.color)
                .font(.system(size: 20))

            Text(message)
                .font(.caffeinateBody)
                .foregroundColor(.caffeinatePrimaryText)
        }
        .padding(.horizontal, .caffeinateSpacingL)
        .padding(.vertical, .caffeinateSpacingM)
        .background(.thinMaterial)
        .cornerRadius(.caffeinateCornerRadiusL)
        .shadow(
            color: Color.black.opacity(0.2),
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let icon: String
    let type: ToastView.ToastType
    let duration: TimeInterval

    func body(content: Content) -> some View {
        ZStack {
            content

            if isPresented {
                VStack {
                    Spacer()

                    ToastView(message: message, icon: icon, type: type)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(.caffeinateEaseInOut) {
                                    isPresented = false
                                }
                            }
                        }

                    Spacer()
                        .frame(height: .caffeinateSpacingXL)
                }
                .animation(.caffeinateSpring, value: isPresented)
            }
        }
    }
}

extension View {
    /// 显示 Toast 通知
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        icon: String = "",
        type: ToastView.ToastType = .info,
        duration: TimeInterval = 3.0
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            icon: icon,
            type: type,
            duration: duration
        ))
    }
}

// MARK: - Loading Overlay

/// 加载遮罩层
struct LoadingOverlay: View {
    let message: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: .caffeinateSpacingM) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(.circular)

                if let message = message {
                    Text(message)
                        .font(.caffeinateBody)
                        .foregroundColor(.white)
                }
            }
            .padding(.caffeinateSpacingXL)
            .background(.ultraThinMaterial)
            .cornerRadius(.caffeinateCornerRadiusL)
        }
    }
}

struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    let message: String?

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)

            if isLoading {
                LoadingOverlay(message: message)
                    .transition(.opacity)
            }
        }
    }
}

extension View {
    /// 显示加载状态
    func loading(
        _ isLoading: Bool,
        message: String? = nil
    ) -> some View {
        modifier(LoadingModifier(
            isLoading: isLoading,
            message: message
        ))
    }
}

// MARK: - Inline Loading Button

/// 带加载状态的按钮
struct LoadingButton<Label: View>: View {
    let isLoading: Bool
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            ZStack {
                label()
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(.circular)
                }
            }
        }
        .disabled(isLoading)
    }
}

// MARK: - Error Banner

/// 错误横幅
struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: .caffeinateSpacingM) {
            Image(systemName: CaffeinateIcon.error)
                .foregroundColor(.caffeinateError)

            Text(message)
                .font(.caffeinateCallout)
                .foregroundColor(.caffeinatePrimaryText)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: CaffeinateIcon.close)
                    .foregroundColor(.caffeinateSecondaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.caffeinateSpacingM)
        .background(Color.caffeinateError.opacity(0.1))
        .cornerRadius(.caffeinateCornerRadiusM)
    }
}

// MARK: - Status Indicator

/// 状态指示器（圆点+文字）
struct StatusIndicator: View {
    let isActive: Bool
    let activeText: String
    let inactiveText: String

    var body: some View {
        HStack(spacing: .caffeinateSpacingXS) {
            Circle()
                .fill(isActive ? Color.caffeinateActive : Color.caffeinateInactive)
                .frame(width: 8, height: 8)

            Text(isActive ? activeText : inactiveText)
                .font(.caffeinateCaption)
                .foregroundColor(.caffeinateSecondaryText)
        }
    }
}

// MARK: - Confirmation Dialog Helper

extension View {
    /// 显示确认对话框
    func confirmationDialog(
        title: String,
        message: String,
        isPresented: Binding<Bool>,
        confirmTitle: String = NSLocalizedString("confirm", bundle: .module, comment: ""),
        confirmRole: ButtonRole? = nil,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.alert(title, isPresented: isPresented) {
            Button(confirmTitle, role: confirmRole, action: onConfirm)
            Button(NSLocalizedString("cancel", bundle: .module, comment: ""), role: .cancel) { }
        } message: {
            Text(message)
        }
    }
}

// MARK: - Empty State

/// 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: .caffeinateSpacingL) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.caffeinateSecondaryText)

            VStack(spacing: .caffeinateSpacingS) {
                Text(title)
                    .font(.caffeinateTitle2)
                    .foregroundColor(.caffeinatePrimaryText)

                Text(message)
                    .font(.caffeinateBody)
                    .foregroundColor(.caffeinateSecondaryText)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .caffeinatePrimaryButton()
                }
            }
        }
        .padding(.caffeinateSpacingXXL)
    }
}

// MARK: - Progress Card

/// 进度卡片（用于显示操作进度）
struct ProgressCard: View {
    let title: String
    let progress: Double  // 0.0 - 1.0
    let message: String?

    var body: some View {
        VStack(alignment: .leading, spacing: .caffeinateSpacingM) {
            Text(title)
                .font(.caffeinateBodyBold)
                .foregroundColor(.caffeinatePrimaryText)

            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)

            if let message = message {
                Text(message)
                    .font(.caffeinateCaption)
                    .foregroundColor(.caffeinateSecondaryText)
            }
        }
        .padding(.caffeinateSpacingL)
        .background(Color.caffeinateCardBackground)
        .cornerRadius(.caffeinateCornerRadiusM)
    }
}

// MARK: - Badge

/// 徽章（用于显示数字或状态）
struct Badge: View {
    let count: Int
    let color: Color

    init(count: Int, color: Color = .caffeinateError) {
        self.count = count
        self.color = color
    }

    var body: some View {
        if count > 0 {
            Text("\(count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color)
                .cornerRadius(10)
        }
    }
}

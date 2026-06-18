// Preferences.swift
// User-facing settings values.

import SwiftUI

enum AppLanguage: String, CaseIterable, Codable, Hashable {
    case system
    case english
    case simplifiedChinese

    var titleKey: String {
        switch self {
        case .system: return "system"
        case .english: return "english"
        case .simplifiedChinese: return "simplified_chinese"
        }
    }

    var appleLanguagesValue: [String]? {
        switch self {
        case .system: return nil
        case .english: return ["en"]
        case .simplifiedChinese: return ["zh-Hans"]
        }
    }
}

enum AppTheme: String, CaseIterable, Codable, Hashable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

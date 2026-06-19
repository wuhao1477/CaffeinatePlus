// AppLocalization.swift
// Explicit module resource lookup for app language preferences.

import Foundation

enum AppLocalization {
  private static let defaultsLanguageKey = "language"

  static func currentLanguage(defaults: UserDefaults = .standard) -> AppLanguage {
    AppLanguage(rawValue: defaults.string(forKey: defaultsLanguageKey) ?? "") ?? .system
  }

  static func localized(_ key: String, language: AppLanguage? = nil) -> String {
    let selectedLanguage = language ?? currentLanguage()
    let bundle = localizedBundle(for: selectedLanguage)
    return bundle.localizedString(forKey: key, value: nil, table: nil)
  }

  static func localizedFormat(_ key: String, _ arguments: CVarArg...) -> String {
    String(format: localized(key), arguments: arguments)
  }

  private static func localizedBundle(for language: AppLanguage) -> Bundle {
    let lprojName = language.lprojName ?? systemLprojName()
    guard
      let lprojName,
      let path = Bundle.module.path(forResource: lprojName, ofType: "lproj"),
      let bundle = Bundle(path: path)
    else {
      return .module
    }

    return bundle
  }

  private static func systemLprojName() -> String? {
    for identifier in Locale.preferredLanguages {
      let normalized = identifier.lowercased()

      if normalized.hasPrefix("zh-hans") || normalized.hasPrefix("zh-cn") {
        return AppLanguage.simplifiedChinese.lprojName
      }

      if normalized.hasPrefix("en") {
        return AppLanguage.english.lprojName
      }
    }

    return nil
  }
}

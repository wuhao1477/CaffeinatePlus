// CaffeinatePlusApp.swift
// 应用主入口
// @main 标记

import SwiftUI

@main
struct CaffeinatePlusApp: App {

  // MARK: - State Objects

  @StateObject private var appState = AppState()

  // MARK: - Scene

  var body: some Scene {
    // 菜单栏应用
    MenuBarExtra {
      PopoverView()
        .environmentObject(appState)
        .preferredColorScheme(appState.theme.colorScheme)
    } label: {
      // 菜单栏图标
      Label {
        Text("CaffeinatePlus")
      } icon: {
        Image(systemName: appState.isActive ? "bolt.fill" : "bolt")
          .symbolRenderingMode(.hierarchical)
      }
    }
    .menuBarExtraStyle(.window)

    Settings {
      SettingsTabView()
        .environmentObject(appState)
        .preferredColorScheme(appState.theme.colorScheme)
    }
  }
}

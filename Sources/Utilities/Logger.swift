// Logger.swift
// 统一日志服务
// 支持控制台输出和文件记录

import Foundation
import os.log

class Logger {

  // MARK: - Singleton

  static let shared = Logger()

  // MARK: - Properties

  private let osLog = OSLog(subsystem: "com.caffeinateplus.app", category: "general")
  private let logFileURL: URL
  private let dateFormatter: DateFormatter

  // MARK: - Initialization

  private init() {
    // 日志文件路径
    let logsDirectory = FileManager.default.urls(
      for: .applicationSupportDirectory,
      in: .userDomainMask
    )[0]
    .appendingPathComponent("CaffeinatePlus")
    .appendingPathComponent("Logs")

    // 创建目录
    try? FileManager.default.createDirectory(
      at: logsDirectory,
      withIntermediateDirectories: true
    )

    logFileURL = logsDirectory.appendingPathComponent("caffeinate-plus.log")

    // 日期格式化器
    dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"  // ISO8601
  }

  // MARK: - Public Methods

  func debug(_ message: String) {
    log(message, level: .debug)
  }

  func info(_ message: String) {
    log(message, level: .info)
  }

  func warning(_ message: String) {
    log(message, level: .warning)
  }

  func error(_ message: String) {
    log(message, level: .error)
  }

  // MARK: - Private Methods

  private func log(_ message: String, level: LogLevel) {
    // 1. 输出到控制台（os_log）
    os_log("%{public}@", log: osLog, type: level.osLogType, message)

    // 2. 写入日志文件
    writeToFile(message, level: level)
  }

  private func writeToFile(_ message: String, level: LogLevel) {
    let timestamp = dateFormatter.string(from: Date())
    let line = "\(timestamp) [\(level.name)] \(message)\n"

    // 追加模式写入
    if let handle = try? FileHandle(forWritingTo: logFileURL) {
      handle.seekToEndOfFile()
      if let data = line.data(using: .utf8) {
        handle.write(data)
      }
      handle.closeFile()
    } else {
      // 文件不存在，创建新文件
      try? line.write(to: logFileURL, atomically: true, encoding: .utf8)
    }
  }
}

// 注意: LogLevel 定义在 MissingPieces.swift 中，避免重复

// 为 LogLevel 添加 Logger 需要的方法
extension LogLevel {
  var name: String {
    switch self {
    case .debug: return "DEBUG"
    case .info: return "INFO"
    case .warning: return "WARNING"
    case .error: return "ERROR"
    }
  }

  var osLogType: OSLogType {
    switch self {
    case .debug: return .debug
    case .info: return .info
    case .warning: return .default
    case .error: return .error
    }
  }
}

// A background app that watches memory pressure (kern.memorystatus_vm_pressure_level)
// and notifies when it rises from normal (1) to warning (2) or higher.
//
// - Shows nothing in the Dock or the menu bar (LSUIElement in Info.plist)
// - Registers itself as a login item on first launch and starts automatically at login
// - Clicking the notification opens Activity Monitor
// - Running with `--unregister` removes the login item and exits
// - Launching with `--test-notification` shows a test notification right after launch
//
// See the Makefile for building and installing.

import AppKit
import Darwin
import os
import ServiceManagement
import UserNotifications

private let logger = Logger(subsystem: "com.github.sonatard.MemoryPressureNotifier", category: "main")

// MARK: - Memory pressure

enum PressureLevel: Int32 {
    case normal = 1
    case warning = 2
    case critical = 4

    var label: String {
        switch self {
        case .normal: "Normal"
        case .warning: "Warning"
        case .critical: "Critical"
        }
    }

    static func current() -> PressureLevel? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &value, &size, nil, 0) == 0 else {
            return nil
        }
        return PressureLevel(rawValue: value)
    }
}

// MARK: - Login item

enum LoginItem {
    static func register() {
        let service = SMAppService.mainApp
        guard service.status != .enabled else { return }
        do {
            try service.register()
        } catch {
            logger.error("Failed to register the login item: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func unregister() {
        do {
            try SMAppService.mainApp.unregister()
        } catch {
            logger.error("Failed to unregister the login item: \(error.localizedDescription, privacy: .public)")
        }
    }
}

// MARK: - App

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private static let interval: Duration = .seconds(5)
    private static let notificationID = "memory-pressure"
    private static let activityMonitorID = "com.apple.ActivityMonitor"

    private var lastLevel: PressureLevel = .normal

    func applicationWillFinishLaunching(_ notification: Notification) {
        // Set the delegate before launch finishes so the response is received even when a notification click launches the app
        UNUserNotificationCenter.current().delegate = self
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        LoginItem.register()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                logger.error("Failed to request notification authorization: \(error.localizedDescription, privacy: .public)")
            } else if !granted {
                logger.notice("Notifications are not allowed")
            }
        }
        if CommandLine.arguments.contains("--test-notification") {
            notify(title: "Memory pressure: Test")
        }
        Task { [weak self] in
            while !Task.isCancelled {
                self?.check()
                try? await Task.sleep(for: Self.interval)
            }
        }
    }

    private func check() {
        guard let level = PressureLevel.current() else { return }
        if lastLevel == .normal, level != .normal {
            notify(title: "Memory pressure: \(level.label)")
        }
        lastLevel = level
    }

    private func notify(title: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Click to open Activity Monitor"
        content.sound = .default
        // Reuse the same ID so old notifications do not pile up in Notification Center
        let request = UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                logger.error("Failed to show the notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func openActivityMonitor() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.activityMonitorID) else {
            logger.error("Activity Monitor not found")
            return
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        await openActivityMonitor()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

@main
enum Main {
    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--unregister") {
            LoginItem.unregister()
            return
        }
        let delegate = AppDelegate()
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}

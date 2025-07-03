//
//  OCRTextApp.swift
//  OCRText
//
//  Created by Nick on 2025/7/3.
//

import SwiftUI
import AppKit
import UserNotifications

@main
struct OCRTextApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 選單列應用程式不需要任何預設視窗
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, NSWindowDelegate {
    var statusBarItem: NSStatusItem?
    var ocrService = OCRService()
    var hotkeyManager = GlobalHotkeyManager()
    private let settings = SettingsManager.shared
    private let historyManager = OCRHistoryManager.shared
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 設定通知委託
        UNUserNotificationCenter.current().delegate = self
        
        // 隱藏應用程式圖示，並且不自動創建視窗
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // 禁用自動創建空白視窗
        NSApplication.shared.mainWindow?.close()
        
        // 建立選單列項目
        setupStatusBar()
        
        // 註冊全域快捷鍵
        setupGlobalHotkey()
        
        // 監聽快捷鍵變更通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutChanged),
            name: .shortcutChanged,
            object: nil
        )
        
        // 監聽歷史記錄變更通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(historyChanged),
            name: NSNotification.Name("OCRHistoryChanged"),
            object: nil
        )
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // 防止重新打開空白視窗
        return false
    }
    
    private func setupStatusBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            button.image = NSImage(systemSymbolName: "doc.text.viewfinder", accessibilityDescription: "OCR Text")
            button.toolTip = "OCR Text - 按 \(settings.getShortcutString()) 進行文字辨識"
        }
        
        updateMenu()
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        // 主要功能選項
        menu.addItem(NSMenuItem(title: "截圖辨識文字 (\(settings.getShortcutString()))", action: #selector(startOCRCapture), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // 歷史記錄區塊
        if !historyManager.isEmpty {
            let historyTitle = NSMenuItem(title: "最近辨識記錄", action: nil, keyEquivalent: "")
            historyTitle.isEnabled = false
            menu.addItem(historyTitle)
            
            for (index, item) in historyManager.historyItems.enumerated() {
                let menuItem = NSMenuItem(
                    title: "\(index + 1). \(item.displayText)",
                    action: #selector(copyHistoryItem(_:)),
                    keyEquivalent: ""
                )
                menuItem.representedObject = item
                menuItem.toolTip = "點擊複製：\(item.text)\n時間：\(item.timeString)"
                menu.addItem(menuItem)
            }
            
            // 清除歷史記錄選項
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "清除歷史記錄", action: #selector(clearHistory), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
        }
        
        // 設定和其他選項
        menu.addItem(NSMenuItem(title: "設定...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "關於", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
        
        // 更新 tooltip
        if let button = statusBarItem?.button {
            button.toolTip = "OCR Text - 按 \(settings.getShortcutString()) 進行文字辨識"
        }
    }
    
    private func setupGlobalHotkey() {
        hotkeyManager.registerGlobalHotkey(
            keyCode: settings.shortcutKeyCode,
            modifiers: settings.shortcutModifiers
        ) { [weak self] in
            self?.startOCRCapture()
        }
    }
    
    @objc private func shortcutChanged() {
        // 重新註冊快捷鍵
        setupGlobalHotkey()
        // 更新選單
        updateMenu()
    }
    
    @objc private func historyChanged() {
        // 更新選單以顯示最新的歷史記錄
        updateMenu()
    }
    
    @objc private func copyHistoryItem(_ sender: NSMenuItem) {
        guard let historyItem = sender.representedObject as? OCRHistoryItem else { return }
        historyManager.copyHistoryItem(historyItem)
        
        // 顯示複製成功的通知
        let content = UNMutableNotificationContent()
        content.title = "文字已複製"
        content.body = "已將歷史記錄複製到剪貼簿"
        content.sound = nil // 不播放聲音
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    @objc private func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "清除歷史記錄"
        alert.informativeText = "確定要清除所有 OCR 歷史記錄嗎？"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "清除")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            historyManager.clearHistory()
            updateMenu()
        }
    }
    
    @objc private func startOCRCapture() {
        ocrService.captureAndRecognizeText()
    }
    
    @objc private func openSettings() {
        // 開啟設定視窗
        print("openSettings called")
        if let window = settingsWindow {
            print("Existing settings window found, bringing to front")
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            print("Creating new settings window")
            openSettingsWindow()
        }
    }
    
    private func openSettingsWindow() {
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.title = "OCR Text 設定"
        window.identifier = NSUserInterfaceItemIdentifier("SettingsWindow")
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.standardWindowButton(.zoomButton)?.isHidden = true // 隱藏放大按鈕
        window.isRestorable = false // 不參與自動恢復
        
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // 保存視窗引用
        settingsWindow = window
        
        // 設定視窗關閉時清除引用
        window.delegate = self
        
        // 確保應用程式激活並顯示視窗
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "OCR Text"
        alert.informativeText = "一個簡單的 OCR 文字辨識工具\n\n使用 \(settings.getShortcutString()) 快捷鍵來截圖並辨識文字\n\n可在設定中自訂快捷鍵"
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 即使應用程式在前景也顯示通知
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 處理使用者點擊通知的動作
        completionHandler()
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow,
           window == settingsWindow {
            settingsWindow = nil
        }
    }
}

//
//  SettingsView.swift
//  OCRText
//
//  Created by Nick on 2025/7/3.
//

import SwiftUI
import AppKit
import Carbon

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @State private var isRecording = false
    @State private var currentShortcut: String = ""
    @State private var eventMonitor: Any?
    
    private enum Tab: String, CaseIterable {
        case shortcut = "快捷鍵"
        case languages = "語言順序"
        case instructions = "說明"
    }
    
    @State private var selectedTab: Tab = .shortcut
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // 根據選擇的 Tab 顯示對應的 View
            switch selectedTab {
            case .shortcut:
                shortcutSettingsView
            case .languages:
                LanguageOrderView()
            case .instructions:
                instructionsView
            }
            
            Spacer()
        }
        .frame(width: 500, height: 380)
        .onAppear {
            currentShortcut = settings.getShortcutString()
        }
        .onDisappear {
            stopRecording()
        }
    }
    
    private var shortcutSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("快捷鍵設定")
                    .font(.headline)
                
                HStack {
                    Text("當前快捷鍵：")
                    
                    Button(action: {
                        if isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    }) {
                        HStack {
                            Text(isRecording ? "按下新的快捷鍵..." : settings.getShortcutString())
                                .foregroundColor(isRecording ? .secondary : .primary)
                                .frame(minWidth: 100)
                            
                            if isRecording {
                                Button("取消") {
                                    stopRecording()
                                }
                                .buttonStyle(.borderless)
                                .foregroundColor(.red)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Text("建議使用 Command、Option、Shift 等修飾鍵組合")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("重設為預設值") {
                    resetToDefault()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
    }
    
    private var instructionsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("使用說明")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. 按下設定的快捷鍵")
                    Text("2. 用滑鼠拖拽選擇要辨識的文字區域")
                    Text("3. 辨識完成後文字會自動複製到剪貼簿")
                    Text("4. 系統會顯示通知告知辨識結果")
                    Text("5. 最近 10 筆記錄會顯示在選單列中")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("語言辨識說明")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("• 支援：🇺🇸 英文、🇯🇵 日文、🇹🇼 繁中、🇨🇳 簡中")
                    Text("• 可在「語言順序」分頁調整辨識優先順序")
                    Text("• 排在前面的語言會優先被辨識")
                    Text("• 建議將不熟悉的語言排在前面")
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func startRecording() {
        isRecording = true
        
        // 建立一個本地事件監聽器來捕捉快捷鍵
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            if self.isRecording {
                self.recordShortcut(event: event)
                return nil // 攔截事件
            }
            return event
        }
    }
    
    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func recordShortcut(event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode
        
        // 確保至少有一個修飾鍵
        if !modifiers.isEmpty {
            var settingsModifiers: NSEvent.ModifierFlags = []
            
            if modifiers.contains(.command) {
                settingsModifiers.insert(.command)
            }
            if modifiers.contains(.option) {
                settingsModifiers.insert(.option)
            }
            if modifiers.contains(.shift) {
                settingsModifiers.insert(.shift)
            }
            if modifiers.contains(.control) {
                settingsModifiers.insert(.control)
            }
            
            // 更新設定
            settings.shortcutKeyCode = keyCode
            settings.shortcutModifiers = settingsModifiers
            settings.saveSettings()
            
            // 更新顯示
            currentShortcut = settings.getShortcutString()
            
            // 停止錄製
            stopRecording()
            
            // 通知 AppDelegate 重新註冊快捷鍵
            NotificationCenter.default.post(name: .shortcutChanged, object: nil)
        }
    }
    
    private func resetToDefault() {
        settings.shortcutKeyCode = UInt16(kVK_ANSI_6)
        settings.shortcutModifiers = [.shift, .option]
        settings.saveSettings()
        currentShortcut = settings.getShortcutString()
        
        // 通知 AppDelegate 重新註冊快捷鍵
        NotificationCenter.default.post(name: .shortcutChanged, object: nil)
    }
}

extension NSNotification.Name {
    static let shortcutChanged = NSNotification.Name("shortcutChanged")
}

#Preview {
    SettingsView()
}

//
//  SettingsManager.swift
//  OCRText
//
//  Created by Nick on 2025/7/3.
//

import Foundation
import Carbon
import AppKit

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var shortcutKeyCode: UInt16 = UInt16(kVK_ANSI_6) // 預設 6
    @Published var shortcutModifiers: NSEvent.ModifierFlags = [.shift, .option] // 預設 Shift+Option
    
    private let keyCodeKey = "ShortcutKeyCode"
    private let modifiersKey = "ShortcutModifiers"
    
    private init() {
        loadSettings()
    }
    
    func loadSettings() {
        let userDefaults = UserDefaults.standard
        
        if userDefaults.object(forKey: keyCodeKey) != nil {
            shortcutKeyCode = UInt16(userDefaults.integer(forKey: keyCodeKey))
        }
        
        if userDefaults.object(forKey: modifiersKey) != nil {
            let rawValue = userDefaults.integer(forKey: modifiersKey)
            shortcutModifiers = NSEvent.ModifierFlags(rawValue: UInt(rawValue))
        }
    }
    
    func saveSettings() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(Int(shortcutKeyCode), forKey: keyCodeKey)
        userDefaults.set(Int(shortcutModifiers.rawValue), forKey: modifiersKey)
    }
    
    func getShortcutString() -> String {
        var modifierString = ""
        
        if shortcutModifiers.contains(.control) {
            modifierString += "⌃"
        }
        if shortcutModifiers.contains(.option) {
            modifierString += "⌥"
        }
        if shortcutModifiers.contains(.shift) {
            modifierString += "⇧"
        }
        if shortcutModifiers.contains(.command) {
            modifierString += "⌘"
        }
        
        let keyString = keyCodeToString(keyCode: shortcutKeyCode)
        return modifierString + keyString
    }
    
    private func keyCodeToString(keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            UInt16(kVK_ANSI_A): "A", UInt16(kVK_ANSI_B): "B", UInt16(kVK_ANSI_C): "C", UInt16(kVK_ANSI_D): "D",
            UInt16(kVK_ANSI_E): "E", UInt16(kVK_ANSI_F): "F", UInt16(kVK_ANSI_G): "G", UInt16(kVK_ANSI_H): "H",
            UInt16(kVK_ANSI_I): "I", UInt16(kVK_ANSI_J): "J", UInt16(kVK_ANSI_K): "K", UInt16(kVK_ANSI_L): "L",
            UInt16(kVK_ANSI_M): "M", UInt16(kVK_ANSI_N): "N", UInt16(kVK_ANSI_O): "O", UInt16(kVK_ANSI_P): "P",
            UInt16(kVK_ANSI_Q): "Q", UInt16(kVK_ANSI_R): "R", UInt16(kVK_ANSI_S): "S", UInt16(kVK_ANSI_T): "T",
            UInt16(kVK_ANSI_U): "U", UInt16(kVK_ANSI_V): "V", UInt16(kVK_ANSI_W): "W", UInt16(kVK_ANSI_X): "X",
            UInt16(kVK_ANSI_Y): "Y", UInt16(kVK_ANSI_Z): "Z",
            UInt16(kVK_ANSI_0): "0", UInt16(kVK_ANSI_1): "1", UInt16(kVK_ANSI_2): "2", UInt16(kVK_ANSI_3): "3",
            UInt16(kVK_ANSI_4): "4", UInt16(kVK_ANSI_5): "5", UInt16(kVK_ANSI_6): "6", UInt16(kVK_ANSI_7): "7",
            UInt16(kVK_ANSI_8): "8", UInt16(kVK_ANSI_9): "9",
            UInt16(kVK_Space): "Space", UInt16(kVK_Return): "Return", UInt16(kVK_Tab): "Tab",
            UInt16(kVK_Delete): "Delete", UInt16(kVK_Escape): "Escape",
            UInt16(kVK_F1): "F1", UInt16(kVK_F2): "F2", UInt16(kVK_F3): "F3", UInt16(kVK_F4): "F4",
            UInt16(kVK_F5): "F5", UInt16(kVK_F6): "F6", UInt16(kVK_F7): "F7", UInt16(kVK_F8): "F8",
            UInt16(kVK_F9): "F9", UInt16(kVK_F10): "F10", UInt16(kVK_F11): "F11", UInt16(kVK_F12): "F12"
        ]
        
        return keyMap[keyCode] ?? "Unknown"
    }
}

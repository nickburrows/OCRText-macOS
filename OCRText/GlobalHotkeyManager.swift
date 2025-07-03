//
//  GlobalHotkeyManager.swift
//  OCRText
//
//  Created by Nick on 2025/7/3.
//

import Foundation
import AppKit
import Carbon

class GlobalHotkeyManager {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var callback: (() -> Void)?
    
    func registerGlobalHotkey(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, callback: @escaping () -> Void) {
        self.callback = callback
        
        // 停止之前的監聽
        stopListening()
        
        // 建立事件監聽
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
                return manager.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        guard let eventTap = eventTap else {
            print("無法建立事件監聽")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }
        
        let settings = SettingsManager.shared
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        
        // 檢查是否匹配設定的快捷鍵
        if UInt16(keyCode) == settings.shortcutKeyCode {
            let expectedModifiers = convertToEventFlags(modifiers: settings.shortcutModifiers)
            let actualModifiers = flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl])
            
            if actualModifiers == expectedModifiers {
                DispatchQueue.main.async {
                    print("快捷鍵觸發: \(settings.getShortcutString())")
                    self.callback?()
                }
                // 攔截事件，不讓其他應用程式處理
                return nil
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func convertToEventFlags(modifiers: NSEvent.ModifierFlags) -> CGEventFlags {
        var flags: CGEventFlags = []
        
        if modifiers.contains(.command) {
            flags.insert(.maskCommand)
        }
        if modifiers.contains(.shift) {
            flags.insert(.maskShift)
        }
        if modifiers.contains(.option) {
            flags.insert(.maskAlternate)
        }
        if modifiers.contains(.control) {
            flags.insert(.maskControl)
        }
        
        return flags
    }
    
    func stopListening() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
    }
    
    deinit {
        stopListening()
    }
}

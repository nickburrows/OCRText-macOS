//
//  OCRHistoryManager.swift
//  OCRText
//
//  Created by Nick on 2025/7/3.
//

import Foundation

struct OCRHistoryItem {
    let id = UUID()
    let text: String
    let timestamp: Date
    
    var displayText: String {
        // 取前 30 個字符作為顯示用途
        let preview = text.count > 30 ? String(text.prefix(30)) + "..." : text
        // 移除換行符號，用空格替代
        return preview.replacingOccurrences(of: "\n", with: " ")
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: timestamp)
    }
}

class OCRHistoryManager: ObservableObject {
    static let shared = OCRHistoryManager()
    
    @Published private(set) var historyItems: [OCRHistoryItem] = []
    private let maxHistoryCount = 10
    private let userDefaultsKey = "OCRHistoryItems"
    
    private init() {
        loadHistory()
    }
    
    func addHistoryItem(text: String) {
        // 過濾空字串或只有空白的文字
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let newItem = OCRHistoryItem(text: trimmedText, timestamp: Date())
        
        // 檢查是否與最近一筆重複
        if let lastItem = historyItems.first, lastItem.text == trimmedText {
            return
        }
        
        // 新增到最前面
        historyItems.insert(newItem, at: 0)
        
        // 限制最大數量
        if historyItems.count > maxHistoryCount {
            historyItems = Array(historyItems.prefix(maxHistoryCount))
        }
        
        saveHistory()
        
        // 發送通知更新選單
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("OCRHistoryChanged"), object: nil)
        }
    }
    
    func copyHistoryItem(_ item: OCRHistoryItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
    }
    
    func clearHistory() {
        historyItems.removeAll()
        saveHistory()
        
        // 發送通知更新選單
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("OCRHistoryChanged"), object: nil)
        }
    }
    
    private func saveHistory() {
        do {
            let historyData = historyItems.map { item in
                ["text": item.text, "timestamp": item.timestamp.timeIntervalSince1970]
            }
            let data = try JSONSerialization.data(withJSONObject: historyData, options: [])
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("儲存歷史記錄失敗: \(error)")
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        
        do {
            if let historyArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                historyItems = historyArray.compactMap { dict in
                    guard let text = dict["text"] as? String,
                          let timestamp = dict["timestamp"] as? TimeInterval else { return nil }
                    return OCRHistoryItem(text: text, timestamp: Date(timeIntervalSince1970: timestamp))
                }
            }
        } catch {
            print("載入歷史記錄失敗: \(error)")
        }
    }
}

import AppKit

extension OCRHistoryManager {
    var isEmpty: Bool {
        historyItems.isEmpty
    }
}

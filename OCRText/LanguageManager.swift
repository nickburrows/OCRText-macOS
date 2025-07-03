//
//  LanguageManager.swift
//  OCRText
//
//  Created by Nick on 2025/7/3.
//

import Foundation

struct OCRLanguage: Codable, Identifiable, Equatable, Hashable {
    let code: String
    let displayName: String
    let flagEmoji: String
    
    var id: String { code }
    
    static let allLanguages = [
        OCRLanguage(code: "en-US", displayName: "English", flagEmoji: "🇺🇸"),
        OCRLanguage(code: "ja-JP", displayName: "日文", flagEmoji: "🇯🇵"),
        OCRLanguage(code: "zh-Hant", displayName: "繁體中文", flagEmoji: "🇹🇼"),
        OCRLanguage(code: "zh-Hans", displayName: "简体中文", flagEmoji: "🇨🇳")
    ]
    
    static func == (lhs: OCRLanguage, rhs: OCRLanguage) -> Bool {
        return lhs.code == rhs.code
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var languageOrder: [OCRLanguage] = []
    private let userDefaultsKey = "OCRLanguageOrder"
    
    private init() {
        loadLanguageOrder()
    }
    
    var recognitionLanguages: [String] {
        return languageOrder.map { $0.code }
    }
    
    func moveLanguage(from source: Int, to destination: Int) {
        guard source != destination,
              source < languageOrder.count,
              destination < languageOrder.count else { return }
        
        let movedLanguage = languageOrder.remove(at: source)
        languageOrder.insert(movedLanguage, at: destination)
        saveLanguageOrder()
        
        // 通知 OCR 服務更新語言設定
        NotificationCenter.default.post(name: .languageOrderChanged, object: nil)
    }
    
    func moveLanguageUp(at index: Int) {
        guard index > 0 else { return }
        moveLanguage(from: index, to: index - 1)
    }
    
    func moveLanguageDown(at index: Int) {
        guard index < languageOrder.count - 1 else { return }
        moveLanguage(from: index, to: index + 1)
    }
    
    func resetToDefault() {
        // 預設順序：日文 > 繁中 > 簡中 > 英文
        languageOrder = [
            OCRLanguage.allLanguages.first { $0.code == "ja-JP" }!,
            OCRLanguage.allLanguages.first { $0.code == "zh-Hant" }!,
            OCRLanguage.allLanguages.first { $0.code == "zh-Hans" }!,
            OCRLanguage.allLanguages.first { $0.code == "en-US" }!
        ]
        saveLanguageOrder()
        NotificationCenter.default.post(name: .languageOrderChanged, object: nil)
    }
    
    func moveLanguages(from source: IndexSet, to destination: Int) {
        languageOrder.move(fromOffsets: source, toOffset: destination)
        saveLanguageOrder()
        NotificationCenter.default.post(name: .languageOrderChanged, object: nil)
    }
    
    func saveLanguageOrder() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(languageOrder.map { $0.code })
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("儲存語言順序失敗: \(error)")
        }
    }
    
    private func loadLanguageOrder() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            resetToDefault()
            return
        }
        
        let decoder = JSONDecoder()
        do {
            let codes = try decoder.decode([String].self, from: data)
            languageOrder = codes.compactMap { code in
                OCRLanguage.allLanguages.first { $0.code == code }
            }
            
            // 確保所有語言都存在，如果有遺漏則重設為預設值
            if languageOrder.count != OCRLanguage.allLanguages.count {
                resetToDefault()
            }
        } catch {
            print("載入語言順序失敗: \(error)")
            resetToDefault()
        }
    }
}

extension Notification.Name {
    static let languageOrderChanged = Notification.Name("languageOrderChanged")
}

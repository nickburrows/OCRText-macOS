//
//  OCRService.swift
//  OCRText
//
//  Created by Nick on 2025/7/3.
//

import Foundation
import Vision
import AppKit
import UniformTypeIdentifiers
import UserNotifications

class OCRService: ObservableObject {
    
    init() {
        setupNotifications()
        
        // 監聽語言順序變更
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageOrderChanged),
            name: .languageOrderChanged,
            object: nil
        )
    }
    
    @objc private func languageOrderChanged() {
        // 語言順序變更時不需要特別處理，performOCR 時會自動使用最新設定
        print("語言辨識順序已更新：\(LanguageManager.shared.recognitionLanguages)")
    }
    
    private func setupNotifications() {
        // 請求通知權限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("通知權限請求失敗: \(error)")
            }
        }
    }
    
    func captureAndRecognizeText() {
        // 直接開始截圖，不隱藏應用程式
        // 因為選單列應用程式本身就不會干擾截圖
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startScreenCapture()
        }
    }
    
    private func startScreenCapture() {
        // 使用 screencapture 指令進行區域截圖
        let tempImagePath = NSTemporaryDirectory() + "ocr_capture.png"
        
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-r", tempImagePath]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        task.terminationHandler = { [weak self] process in
            DispatchQueue.main.async {
                if process.terminationStatus == 0 {
                    // 截圖成功，開始 OCR
                    print("截圖成功，開始進行 OCR")
                    self?.performOCR(imagePath: tempImagePath)
                } else {
                    // 截圖取消或失敗
                    print("截圖取消或失敗，狀態碼: \(process.terminationStatus)")
                    self?.cleanup(imagePath: tempImagePath)
                }
            }
        }
        
        task.launch()
        print("已啟動螢幕截圖程序")
    }
    
    private func performOCR(imagePath: String) {
        guard let image = NSImage(contentsOfFile: imagePath) else {
            print("無法載入圖片")
            cleanup(imagePath: imagePath)
            return
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("無法轉換圖片格式")
            cleanup(imagePath: imagePath)
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            if let error = error {
                print("OCR 錯誤: \(error)")
                self?.cleanup(imagePath: imagePath)
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                print("無法取得 OCR 結果")
                self?.cleanup(imagePath: imagePath)
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                self?.copyToClipboard(text: recognizedText)
                self?.cleanup(imagePath: imagePath)
                
                // 加入歷史記錄
                OCRHistoryManager.shared.addHistoryItem(text: recognizedText)
                
                // 顯示通知
                self?.showNotification(text: recognizedText)
            }
        }
        
        // 設定 OCR 選項
        request.recognitionLevel = .accurate
        request.recognitionLanguages = LanguageManager.shared.recognitionLanguages
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("執行 OCR 時發生錯誤: \(error)")
            cleanup(imagePath: imagePath)
        }
    }
    
    private func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        print("文字已複製到剪貼簿: \(text)")
    }
    
    private func showNotification(text: String) {
        let content = UNMutableNotificationContent()
        content.title = "OCR 完成"
        
        if text.isEmpty {
            content.body = "未識別到文字"
        } else {
            let preview = text.count > 50 ? String(text.prefix(50)) + "..." : text
            content.body = "已識別文字並複製到剪貼簿：\n\(preview)"
        }
        
        content.sound = .default
        
        // 建立通知請求
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 立即顯示
        )
        
        // 發送通知
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("發送通知失敗: \(error)")
            }
        }
    }
    
    private func cleanup(imagePath: String) {
        // 清理暫存檔
        try? FileManager.default.removeItem(atPath: imagePath)
    }
}

extension NSImage {
    var cgImage: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }
}

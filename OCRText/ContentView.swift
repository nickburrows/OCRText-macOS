//
//  ContentView.swift
//  OCRText
//
//  Created by Nick on 2025/7/3.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.viewfinder")
                .imageScale(.large)
                .foregroundStyle(.tint)
                .font(.system(size: 50))
            
            Text("OCR Text")
                .font(.title)
                .fontWeight(.bold)
            
            Text("這是一個選單列應用程式")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("請在選單列中找到 OCR Text 圖示來使用")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300, height: 200)
    }
}

#Preview {
    ContentView()
}

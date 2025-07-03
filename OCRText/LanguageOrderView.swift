//
//  LanguageOrderView.swift
//  OCRText
//
//  Created by Nick on 2025/7/3.
//

import SwiftUI

struct LanguageOrderView: View {
    @ObservedObject private var languageManager = LanguageManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text("語言辨識順序")
                    .font(.headline)
                Text("拖曳調整語言的優先順序，排在前面的語言會優先被辨識。")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            List {
                ForEach(languageManager.languageOrder, id: \.self) { language in
                    HStack {
                        Text(language.displayName)
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onMove(perform: move)
            }
            .listStyle(DefaultListStyle())
            .frame(height: 200) // 給予一個固定高度

            HStack {
                Text("預設：🇯🇵 🇹🇼 🇨🇳 🇺🇸")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("重設為預設順序") {
                    languageManager.resetToDefault()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
    }

    private func move(from source: IndexSet, to destination: Int) {
        languageManager.moveLanguages(from: source, to: destination)
    }
}

struct LanguageOrderView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageOrderView()
    }
}

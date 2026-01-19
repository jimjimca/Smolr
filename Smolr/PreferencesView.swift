//
//  PreferencesView.swift
//  Smolr
//
//  Created by Jimmy Houle on 2026-01-17.
//

import SwiftUI

struct PreferencesView: View {
    @AppStorage("defaultFormat") private var defaultFormat = "original"
    @AppStorage("defaultQuality") private var defaultQuality = 85
    @AppStorage("fileSuffix") private var fileSuffix = "_smolr"
    @AppStorage("hideWarnings") private var hideWarnings = false
    @AppStorage("accentColor") private var accentColorName = "blue"
    
    var body: some View {
        Form {
            Section("Default Conversion Settings") {
                Picker("Default Format:", selection: $defaultFormat) {
                    Text("Original").tag("original")
                    Text("WebP").tag("webp")
                    Text("AVIF").tag("avif")
                    Text("JXL").tag("jxl")
                }
                .pickerStyle(.menu)
                
                HStack {
                    Text("Default Quality:")
                    Slider(value: Binding(
                        get: { Double(defaultQuality) },
                        set: { defaultQuality = Int($0) }
                    ), in: 50...100, step: 5)
                    Text("\(defaultQuality)%")
                        .frame(width: 45)
                }
            }
            
            Section("File Naming") {
                TextField("File Suffix:", text: $fileSuffix)
                Text("Output files will be named: filename\(fileSuffix).ext")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Interface") {
                Toggle("Hide Warnings", isOn: $hideWarnings)
                
                Picker("Accent Color:", selection: $accentColorName) {
                    Text("Blue").tag("blue")
                    Text("Purple").tag("purple")
                    Text("Pink").tag("pink")
                    Text("Orange").tag("orange")
                    Text("Green").tag("green")
                }
                .pickerStyle(.menu)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 400)
    }
}

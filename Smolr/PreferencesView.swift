// Smolr
// Copyright (c) 2026 Jimmy Houle
// Licensed under BSD 3-Clause License
// See README.md for third-party licenses
import SwiftUI

struct PreferencesView: View {
    
    
    // MARK: - App Storage
    
    @AppStorage("defaultFormat") private var defaultFormat = "original"
    @AppStorage("defaultQuality") private var defaultQuality = 85
    @AppStorage("fileSuffix") private var fileSuffix = "_smolr"
    @AppStorage("hideWarnings") private var hideWarnings = false
    @AppStorage("accentColor") private var accentColorName = "blue"
    @AppStorage("enabledFormats") private var enabledFormatsString = FormatConfig.defaultEnabledFormats
    @AppStorage("optimizationProfile") private var optimizationProfileRaw = OptimizationProfile.balanced.rawValue
    
    
    // MARK: - Computed Preferences
    
    private var optimizationProfile: OptimizationProfile {
        get {
            OptimizationProfile(rawValue: optimizationProfileRaw) ?? .balanced
        }
        set {
            optimizationProfileRaw = newValue.rawValue
        }
    }
    
    private var enabledFormats: Set<String> {
        get {
            Set(enabledFormatsString.split(separator: ",").map { String($0) })
        }
    }
    
    // MARK: - Format Management

    private func toggleFormat(_ format: String) {
        var formats = enabledFormats
        if formats.contains(format) {
            if format == defaultFormat {
                return
            }
            formats.remove(format)
        } else {
            formats.insert(format)
        }
        enabledFormatsString = formats.sorted().joined(separator: ",")
    }

    private func isFormatEnabled(_ format: String) -> Bool {
        enabledFormats.contains(format)
    }

    private func ensureDefaultFormatEnabled() {
        var formats = enabledFormats
        if !formats.contains(defaultFormat) {
            formats.insert(defaultFormat)
            enabledFormatsString = formats.sorted().joined(separator: ",")
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Form {
            Section("Default Conversion Settings") {
                Picker("Default Format:", selection: $defaultFormat) {
                    ForEach(FormatConfig.allFormats, id: \.self) { format in
                        Text(FormatConfig.displayName(for: format)).tag(format)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: defaultFormat) { _, _ in
                    ensureDefaultFormatEnabled()
                }

                
                HStack {
                    Text("Default Quality:")
                    Slider(value: Binding(
                        get: { Double(defaultQuality) },
                        set: { defaultQuality = Int($0) }
                    ), in: 50...100, step: 5)
                    Text("\(defaultQuality)%")
                        .frame(width: 45)
                }
                Picker("Optimization Profile:", selection: $optimizationProfileRaw) {
                    ForEach(OptimizationProfile.allCases, id: \.self) { profile in
                        Text(profile.displayName).tag(profile.rawValue)
                    }
                }
                .pickerStyle(.menu)
                
                Text((OptimizationProfile(rawValue: optimizationProfileRaw) ?? .balanced).description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            
            
            Section("Available Formats") {
                ForEach(Array(stride(from: 0, to: FormatConfig.allFormats.count, by: 2)), id: \.self) { index in
                    HStack(spacing: 32) {
                        let format1 = FormatConfig.allFormats[index]
                        Toggle(FormatConfig.displayName(for: format1), isOn: Binding(
                            get: { isFormatEnabled(format1) },
                            set: { _ in toggleFormat(format1) }
                        ))
                        .disabled(defaultFormat == format1)
                        
                        if index + 1 < FormatConfig.allFormats.count {
                            let format2 = FormatConfig.allFormats[index + 1]
                            Toggle(FormatConfig.displayName(for: format2), isOn: Binding(
                                get: { isFormatEnabled(format2) },
                                set: { _ in toggleFormat(format2) }
                            ))
                            .disabled(defaultFormat == format2)
                        }
                    }
                }
                
                
                Text("Select formats to be displayed on the format picker. The default format is always enabled.")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                .onChange(of: defaultFormat) { _, _ in
                    ensureDefaultFormatEnabled()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 400)
    }
}

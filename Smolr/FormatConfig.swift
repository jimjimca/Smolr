//
//  FormatConfig.swift
//  Smolr
//
//  Created by Jimmy Houle on 2026-01-29.
//
import Foundation

struct FormatConfig {
    static let allFormats = ["original", "webp", "avif", "jxl", "png", "jpeg"]
    static let defaultEnabledFormats = "original,webp,avif,jxl"
    
    static func displayName(for format: String) -> String {
        switch format.lowercased() {
        case "original": return "Original"
        case "webp": return "WebP"
        case "avif": return "AVIF"
        case "jxl": return "JXL"
        case "png": return "PNG"
        case "jpeg": return "JPEG"
        default: return format.uppercased()
        }
    }
    
    static func sortedFormats(_ formats: [String]) -> [String] {
        formats.sorted { format1, format2 in
            let index1 = allFormats.firstIndex(of: format1) ?? 999
            let index2 = allFormats.firstIndex(of: format2) ?? 999
            return index1 < index2
        }
    }
}

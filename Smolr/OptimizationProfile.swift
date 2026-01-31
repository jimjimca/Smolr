//
//  OptimizationProfile.swift
//  Smolr
//
//  Created by Jimmy Houle on 2026-01-29.
//

import Foundation

enum OptimizationProfile: String, CaseIterable {
    case fast = "fast"
    case balanced = "balanced"
    case quality = "quality"
    case size = "size"
    
    var displayName: String {
        switch self {
        case .fast: return "Fast"
        case .balanced: return "Balanced"
        case .quality: return "Quality (slower)"
        case .size: return "Size (smallest)"
        }
    }
    
    var description: String {
        switch self {
        case .fast: return "Quick processing with basic optimization"
        case .balanced: return "Good balance between speed and quality"
        case .quality: return "Maximum quality. Takes significantly more time"
        case .size: return "Smallest file size, more aggressive compression. Takes significantly more time"
        }
    }
}

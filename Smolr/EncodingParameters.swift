//
//  EncodingParameters.swift
//  Smolr
//
//  Created by Jimmy Houle on 2026-01-29.
//

import Foundation

struct EncodingParameters {
    
    // MARK: - PNG Parameters
    
    static func pngParameters(profile: OptimizationProfile, quality: Int) -> [String] {
        if quality == 100 {
            // Lossless optimization with oxipng
            switch profile {
            case .fast:
                return ["-o", "2", "--strip", "safe"]
            case .balanced:
                return ["-o", "3", "--strip", "safe"]
            case .quality:
                return ["-o", "4", "--strip", "safe"]
            case .size:
                return ["-o", "6", "--strip", "all"]
            }
        } else {
            // Lossy with pngquant - returns (pngquant args, oxipng args)
            let speed: String
            switch profile {
            case .fast:
                speed = "10"
            case .balanced:
                speed = "4"
            case .quality:
                speed = "1"
            case .size:
                speed = "1"
            }
            return ["--quality", "\(quality)-\(quality)", "--speed", speed, "--force", "--strip"]
        }
    }
    
    static func pngOptimizationLevel(profile: OptimizationProfile) -> String {
        switch profile {
        case .fast: return "2"
        case .balanced: return "3"
        case .quality: return "4"
        case .size: return "max"
        }
    }
    
    // MARK: - JPEG Parameters
    
    static func jpegParameters(profile: OptimizationProfile, quality: Int) -> [String] {
        var params = ["-quality", "\(quality)"]
        
        switch profile {
        case .fast:
            params += ["-optimize"]
        case .balanced:
            params += ["-optimize", "-progressive"]
        case .quality:
            params += ["-optimize", "-progressive"]
        case .size:
            params += ["-optimize", "-progressive", "-smooth", "10"]
        }
        
        return params
    }
    
    // MARK: - GIF Parameters
    
    static func gifParameters(profile: OptimizationProfile, quality: Int) -> [String] {
        let lossiness = 100 - quality
        var params: [String]
        
        switch profile {
        case .fast:
            params = ["-O2", "--lossy=\(lossiness)"]
        case .balanced:
            params = ["-O3", "--lossy=\(lossiness)"]
        case .quality:
            params = ["-O3", "--lossy=\(max(0, lossiness - 10))"]
        case .size:
            params = ["-O3", "--lossy=\(min(200, lossiness + 20))"]
        }
        
        params += ["--no-comments", "--no-extensions", "--no-names"]
        return params
    }
    
    // MARK: - WebP Parameters
    
    static func webpParameters(profile: OptimizationProfile, quality: Int) -> [String] {
        var params = ["-q", "\(quality)", "-metadata", "none"]
        
        switch profile {
        case .fast:
            params += ["-m", "0"]
        case .balanced:
            params += ["-m", "4"]
        case .quality:
            params += ["-m", "6", "-pass", "10", "-af"]
        case .size:
            params += ["-m", "6", "-pass", "10"]
        }
        
        return params
    }
    
    // MARK: - AVIF Parameters
    
    static func avifParameters(profile: OptimizationProfile, quality: Int) -> [String] {
        var params = ["-q", "\(quality)", "--ignore-exif", "--ignore-xmp"]
        
        switch profile {
        case .fast:
            params += ["-s", "10"]
        case .balanced:
            params += ["-s", "4"]
        case .quality:
            params += ["-s", "0", "--min", "0", "--max", "56"]
        case .size:
            params += ["-s", "0"]
        }
        
        return params
    }
    
    // MARK: - JPEG XL Parameters
    
    static func jxlParameters(profile: OptimizationProfile, quality: Int, lossless: Bool) -> [String] {
        if lossless {
            switch profile {
            case .fast:
                return ["--lossless_jpeg=1", "-e", "3"]
            case .balanced:
                return ["--lossless_jpeg=1", "-e", "5"]
            case .quality:
                return ["--lossless_jpeg=1", "-e", "9"]
            case .size:
                return ["--lossless_jpeg=1", "-e", "9"]
            }
        } else {
            var params = ["--lossless_jpeg=0", "-q", "\(quality)"]
            
            switch profile {
            case .fast:
                params += ["-e", "3"]
            case .balanced:
                params += ["-e", "5"]
            case .quality:
                params += ["-e", "9"]
            case .size:
                params += ["-e", "9"]
            }
            
            return params
        }
    }
}

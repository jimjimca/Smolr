//
//  UpdateChecker.swift
//  Smolr
//
//  Created by Jimmy Houle on 2026-01-18.
//

import Foundation

struct VersionInfo: Codable, Sendable {
    let version: String
    let downloadURL: String
}

struct UpdateChecker {
    static let currentVersion = "1.0.0"
    
    static func checkForUpdates(completion: @escaping @Sendable (Bool, String?, URL?) -> Void) {
        guard let url = URL(string: "https://raw.githubusercontent.com/jimjimca/Smolr/main/latest.json") else {
            completion(false, nil, nil)
            return
        }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let json = try JSONDecoder().decode(VersionInfo.self, from: data)
                
                await MainActor.run {
                    let updateAvailable = isNewerVersion(json.version, than: currentVersion)
                    let downloadURL = URL(string: json.downloadURL)
                    completion(updateAvailable, json.version, downloadURL)
                }
            } catch {
                await MainActor.run {
                    completion(false, nil, nil)
                }
            }
        }
    }
    
    static func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newParts = new.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(newParts.count, currentParts.count) {
            let newPart = i < newParts.count ? newParts[i] : 0
            let currentPart = i < currentParts.count ? currentParts[i] : 0
            
            if newPart > currentPart { return true }
            if newPart < currentPart { return false }
        }
        return false
    }
}

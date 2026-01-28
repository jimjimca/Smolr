//
//  Logger.swift
//  Smolr
//
//  Created by Jimmy Houle on 2026-01-26.
//

import OSLog

enum SmolrLogger {
    nonisolated static let conversion = Logger(subsystem: "com.jimjim.Smolr", category: "conversion")
}
//To log : SmolrLogger.conversion.debug("Failed to run command: \(error, privacy: .public)")

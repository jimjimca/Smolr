// Smolr
// Copyright (c) 2026 Jimmy Houle
// Licensed under BSD 3-Clause License
// See README.md for third-party licenses
import SwiftUI
import UniformTypeIdentifiers
import Combine
import OSLog


// MARK: - Supporting Types

class FileItem: Identifiable, Hashable, ObservableObject {
    let id = UUID()
    let url: URL
    @Published var status: ConversionStatus = .notStarted
    
    init(url: URL) {
        self.url = url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum ConversionStatus {
    case notStarted
    case waiting
    case converting
    case done
    case failed
    case warning(String)
    
    var description: String {
        switch self {
        case .notStarted: return ""
        case .waiting: return "Waiting"
        case .converting: return "Converting..."
        case .done: return "Done"
        case .failed: return "Failed"
        case .warning(let message): return message
        }
    }
}

struct ImageValidator {
    static let imageExtensions = ["png", "jpg", "jpeg", "tiff", "tif", "bmp", "gif", "heic", "webp", "avif", "jxl"]
    
    static func isImageFile(_ url: URL) -> Bool {
        imageExtensions.contains(url.pathExtension.lowercased())
    }
}


// MARK: - Status Icon View

struct StatusIconView: View {
    let status: ConversionStatus
    let accentColor: Color
    @State private var isRotating = false
    
    
    var body: some View {
        Group {
            switch status {
            case .waiting:
                Image(systemName: "clock")
                    .foregroundColor(.gray)
                    .frame(width: 16, height: 16)
            case .converting:
                Image(systemName: "progress.indicator")
                                    .foregroundColor(accentColor)
                                    .rotationEffect(.degrees(isRotating ? 360 : 0))
                                    .onAppear {
                                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                            isRotating = true
                                        }
                                    }
                    
            case .done:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.gray)
                    .frame(width: 16, height: 16)
            case .notStarted:
                EmptyView()
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red.opacity(0.6))
                    .frame(width: 16, height: 16)
            case .warning:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .frame(width: 16, height: 16)
            }
        }
        .help(status.description)
    }
}


// MARK: - File Item Row

struct FileItemRow: View {
    @ObservedObject var file: FileItem
    let isTargeted: Bool
    let processedFiles: Set<UUID>
    let accentColor: Color
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(file.url.lastPathComponent)
                .italic(isFailed)
                .foregroundColor(
                    isSelected ? .white :
                    isFailed ? .gray :
                    isTargeted ? (ImageValidator.isImageFile(file.url) ? accentColor : .gray) : .gray
                )
                .opacity(
                    isFailed ? 0.75 :
                    isTargeted ? (ImageValidator.isImageFile(file.url) ? 0.75 : 0.35) :
                    (processedFiles.contains(file.id) ? 0.35 : (ImageValidator.isImageFile(file.url) ? 1.0 : 0.25))
                )
            Spacer()
            
            if ImageValidator.isImageFile(file.url), !isNotStarted {
                StatusIconView(status: file.status, accentColor: accentColor)
            } else if !ImageValidator.isImageFile(file.url) {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red.opacity(0.5))
                    .frame(width: 16, height: 16)
                    .help("Not an image file")
            }
        }
        .listRowBackground(
            isSelected ? accentColor.opacity(1.0) : Color.clear
                )
    }
    
    private var isFailed: Bool {
        if case .failed = file.status { return true }
        return false
    }
    
    private var isNotStarted: Bool {
        if case .notStarted = file.status { return true }
        return false
    }
}


// MARK: - Content View

struct ContentView: View {
    
    
    // MARK: - Properties
        
    // App Storage
    @AppStorage("defaultFormat") private var defaultFormat = "original"
    @State private var outputFormat = "original"
    @AppStorage("defaultQuality") private var quality = 85
    @AppStorage("fileSuffix") private var fileSuffix = "_smolr"
    @AppStorage("hideWarnings") private var hideWarnings = false
    @AppStorage("accentColor") private var accentColorName = "blue"
    @AppStorage("enabledFormats") private var enabledFormatsString = FormatConfig.defaultEnabledFormats
    @AppStorage("optimizationProfile") private var optimizationProfileRaw = OptimizationProfile.balanced.rawValue
    
    // State
    
    @State private var droppedFiles: [FileItem] = []
    @State private var isTargeted = false
    @State private var isHovering = false
    @State private var selectedFiles: Set<FileItem> = []
    @State private var processedFiles: Set<UUID> = []
    @State private var totalFilesToConvert = 0
    @State private var filesConverted = 0
    @State private var conversionTask: Task<Void, Never>?
    @State private var errorMessages: [String] = []
    @State private var warningMessages: [String] = []
    @State private var totalBytesSaved: Int64 = 0
    @State private var totalOriginalBytes: Int64 = 0
    
    // Computed Properties
    
    private var accentColor: Color {
        switch accentColorName {
        case "purple": return .purple
        case "pink": return Color(red: 1.0, green: 0.4, blue: 0.8)
        case "orange": return .orange
        case "green": return .green
        default: return .blue
        }
    }
    
    private var optimizationProfile: OptimizationProfile {
        OptimizationProfile(rawValue: optimizationProfileRaw) ?? .balanced
    }
    
    private var enabledFormats: [String] {
        let formats = enabledFormatsString.split(separator: ",").map { String($0) }
        return FormatConfig.sortedFormats(formats)
    }
    
    
    // MARK: - Helper Functions
    
    func getFileSize(url: URL) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }
        return fileSize
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: bytes)
    }
    
    func calculatePickerWidth() -> CGFloat {
        let baseWidth: CGFloat = 40
        let charWidth: CGFloat = 10
        
        let totalChars = enabledFormats.reduce(0) { total, format in
            total + FormatConfig.displayName(for: format).count
        }
        
        return baseWidth + CGFloat(totalChars) * charWidth
    }
    
    func getBundledToolPath(for tool: String) -> String? {
        if let resourcePath = Bundle.main.resourcePath {
            let toolPath = (resourcePath as NSString).appendingPathComponent("Tools/\(tool)")
            if FileManager.default.fileExists(atPath: toolPath) {
                return toolPath
            }
        }
        return nil
    }
    
    func buildOutputURL(for inputURL: URL) -> URL {
        let directory = inputURL.deletingLastPathComponent()
        let filename = inputURL.deletingPathExtension().lastPathComponent
        let inputExt = inputURL.pathExtension
        
        let outputExt = outputFormat == "original" ? inputExt : outputFormat
        
        let newFilename = "\(filename)\(fileSuffix).\(outputExt)"
        
        return directory.appendingPathComponent(newFilename)
    }
    
    
    // MARK: - UI Interaction
    
    func toggleSelection(_ file: FileItem, multiSelect: Bool) {
        if multiSelect {
            if selectedFiles.contains(file) {
                selectedFiles.remove(file)
            } else {
                selectedFiles.insert(file)
            }
        } else {
            selectedFiles = [file]
        }
    }
    
    func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        
        panel.begin { response in
            if response == .OK {
                totalFilesToConvert = 0
                filesConverted = 0
                errorMessages.removeAll()
                
                DispatchQueue.main.async {
                    for url in panel.urls {
                        self.addURLToDroppedFiles(url)
                    }
                    
                    self.checkForOutputConflicts()
                    self.checkDiskSpace()
                }
            }
        }
    }
    
    
    // MARK: - File Management
    
    func handleDrop(droppedItems: [NSItemProvider]) -> Bool {
        
        totalFilesToConvert = 0
        filesConverted = 0
        errorMessages.removeAll()
        
        for droppedItem in droppedItems {
            droppedItem.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    
                    return
                }
                
                DispatchQueue.main.async {
                    self.addURLToDroppedFiles(url)
                    
                    self.checkForOutputConflicts()
                    self.checkDiskSpace()
                }
            }
        }
        return true
    }
    
    func addURLToDroppedFiles(_ url: URL) {
        var isDirectory: ObjCBool = false
        
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue {
                enumerateImagesInDirectory(url)
            } else {
                droppedFiles.append(FileItem(url: url))
            }
        }
    }
    
    func enumerateImagesInDirectory(_ directory: URL) {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return
        }
        
        var foundFiles: [FileItem] = []
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  let isRegularFile = resourceValues.isRegularFile,
                  isRegularFile else {
                continue
            }
            
            if ImageValidator.isImageFile(fileURL) {
                foundFiles.append(FileItem(url: fileURL))
            }
        }
        
        droppedFiles.append(contentsOf: foundFiles)
    }
    
    
    // MARK: - Validation & Warnings
    
    func showErrorMessage(_ message: String) {
        errorMessages.append(message)
    }
    
    func showWarningMessage(_ message: String) {
        if !warningMessages.contains(message) {
            warningMessages.append(message)
        }
    }
    
    func checkForOutputConflicts() {
        var hasConflicts = false
        
        for file in droppedFiles {
            guard ImageValidator.isImageFile(file.url), !processedFiles.contains(file.id) else { continue }
            
            let outputURL = buildOutputURL(for: file.url)
            if FileManager.default.fileExists(atPath: outputURL.path) {
                file.status = .warning("Existing output file will be overwritten")
                hasConflicts = true
            } else if case .warning = file.status {
                file.status = .notStarted
            }
        }
        
        warningMessages.removeAll { $0.contains("will be overwritten") }
        if hasConflicts {
            showWarningMessage("Some files will be overwritten")
        }
    }
    
    func checkFilePermissions(inputURL: URL, outputURL: URL) -> (canRead: Bool, canWrite: Bool) {
        let canRead = FileManager.default.isReadableFile(atPath: inputURL.path)
        let outputDir = outputURL.deletingLastPathComponent()
        let canWrite = FileManager.default.isWritableFile(atPath: outputDir.path)
        
        return (canRead, canWrite)
    }

    func checkDiskSpace() {
        if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
            let freeSize = attributes[.systemFreeSize] as? Int64 {
            let freeGB = Double(freeSize) / 1_000_000_000
                if freeGB < 1.0 {  // Less than 1GB free
                    showWarningMessage("Low disk space (\(String(format: "%.1f", freeGB))GB free)")
                }
            }
    }
    
    
    // MARK: - Conversion Logic
    
    func convertFiles() {
        conversionTask = Task {
            warningMessages.removeAll()
            let filesToConvert = droppedFiles.filter { ImageValidator.isImageFile($0.url) && !processedFiles.contains($0.id) }
            totalFilesToConvert = filesToConvert.count
            filesConverted = 0
            totalBytesSaved = 0
            totalOriginalBytes = 0

            
            for file in droppedFiles {
                if ImageValidator.isImageFile(file.url) && !processedFiles.contains(file.id) {
                    file.status = .waiting
                }
            }
            
            for file in droppedFiles {
                if Task.isCancelled || !droppedFiles.contains(where: { $0.id == file.id }) {
                    break
                }
                
                guard ImageValidator.isImageFile(file.url) && !processedFiles.contains(file.id) else {
                    continue
                }
                
                file.status = .converting
                
                let startTime = Date()
                let outputURL = buildOutputURL(for: file.url)
                let originalSize = getFileSize(url: file.url)
                
                let permissions = checkFilePermissions(inputURL: file.url, outputURL: outputURL)
                if !permissions.canRead {
                    file.status = .failed
                    showErrorMessage("Cannot read \(file.url.lastPathComponent) - permission denied")
                    continue
                }
                if !permissions.canWrite {
                    file.status = .failed
                    showErrorMessage("Cannot write to output directory - permission denied")
                    continue
                }
                
                let success = await convertFile(inputURL: file.url, outputURL: outputURL)
                
                guard droppedFiles.contains(where: { $0.id == file.id }) else {
                    continue
                }
                
                if success {
                    let duration = Date().timeIntervalSince(startTime)
                    processedFiles.insert(file.id)
                    file.status = .done
                    filesConverted += 1
                    SmolrLogger.conversion.info("✓ Converted \(file.url.lastPathComponent) in \(String(format: "%.2f", duration))s")
                    if let origSize = originalSize,
                       let newSize = getFileSize(url: outputURL) {
                        totalOriginalBytes += origSize
                        totalBytesSaved += (origSize - newSize)
                    }
                } else {
                    
                    file.status = .failed
                    showErrorMessage("Failed to convert \(file.url.lastPathComponent)")
                }
            }
            warningMessages.removeAll { $0.contains("will be overwritten") }
        }
    }
    
    func convertFile(inputURL: URL, outputURL: URL) async -> Bool {
        let inputExt = inputURL.pathExtension.lowercased()
        let targetFormat = outputFormat == "original" ? inputExt : outputFormat.lowercased()
        
        SmolrLogger.conversion.debug("Converting \(inputURL.lastPathComponent) (\(inputExt)) to \(targetFormat)")
        
        if inputExt == targetFormat {
            guard let commandClosure = getEncodingCommand(for: targetFormat, inputPath: inputURL.path, outputPath: outputURL.path, quality: quality) else {
                SmolrLogger.conversion.error("No encoder for \(targetFormat)")
                return false
            }
            return await commandClosure()
        }
        
        return await convertViaIntermediate(inputURL: inputURL, outputURL: outputURL)
    }
    
    func convertViaIntermediate(inputURL: URL, outputURL: URL) async -> Bool {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".png")
        
        SmolrLogger.conversion.debug("convertViaIntermediate: Decoding \(inputURL.lastPathComponent) to temp PNG")
        let decodeSuccess = await decodeToFormat(inputURL: inputURL, outputPath: tempURL.path)
        SmolrLogger.conversion.debug("Decode result: \(decodeSuccess)")
        
        guard decodeSuccess else {
            SmolrLogger.conversion.error("Failed to decode \(inputURL.lastPathComponent)")
            return false
        }
        
        let targetFormat = outputFormat == "original" ? outputURL.pathExtension.lowercased() : outputFormat.lowercased()
        
        SmolrLogger.conversion.debug("Now encoding temp PNG to \(targetFormat)")
        guard let commandClosure = getEncodingCommand(for: targetFormat, inputPath: tempURL.path, outputPath: outputURL.path, quality: quality) else {
            SmolrLogger.conversion.error("No encoding command for format: \(targetFormat)")
            try? FileManager.default.removeItem(at: tempURL)
            return false
        }
        
        let success = await commandClosure()
        SmolrLogger.conversion.debug("Encode result: \(success)")
        try? FileManager.default.removeItem(at: tempURL)
        return success
    }
    
    
    // MARK: - Encoding Commands
    
    func getEncodingCommand(
        for format: String,
        inputPath: String,
        outputPath: String,
        quality: Int
    ) -> (() async -> Bool)? {
        SmolrLogger.conversion.debug("getEncodingCommand called: format=\(format), input=\(inputPath), quality=\(quality)")

        switch format.lowercased() {
        case "png":
            if quality == 100 {
                guard let oxipngPath = getBundledToolPath(for: "oxipng") else { return nil }
                let params = EncodingParameters.pngParameters(profile: optimizationProfile, quality: quality)
                return {
                    await runCommand(
                        executable: oxipngPath,
                        arguments: params + [inputPath, "--out", outputPath]
                    )
                }
            } else {
                guard let pngquantPath = getBundledToolPath(for: "pngquant"),
                      let oxipngPath = getBundledToolPath(for: "oxipng") else { return nil }
                let pngquantParams = EncodingParameters.pngParameters(profile: optimizationProfile, quality: quality)
                let oxipngLevel = EncodingParameters.pngOptimizationLevel(profile: optimizationProfile)
                return {
                    var success = await runCommand(
                        executable: pngquantPath,
                        arguments: pngquantParams + ["--output", outputPath, inputPath]
                    )
                    if !success {
                        success = await runCommand(
                            executable: oxipngPath,
                            arguments: ["-o", oxipngLevel, "--strip", "all", inputPath, "--out", outputPath]
                        )
                    }
                    return success
                }
            }
            
        case "jpg", "jpeg":
            guard let cjpegPath = getBundledToolPath(for: "cjpeg") else { return nil }
            let cjpegParams = EncodingParameters.jpegParameters(profile: optimizationProfile, quality: quality)
            return {
                await runCommand(
                    executable: cjpegPath,
                    arguments: cjpegParams + ["-outfile", outputPath, inputPath]
                )
            }
            
        case "gif":
            guard let gifsiclePath = getBundledToolPath(for: "gifsicle") else { return nil }
            let params = EncodingParameters.gifParameters(profile: optimizationProfile, quality: quality)
            return {
                await runCommand(
                    executable: gifsiclePath,
                    arguments: params + ["-o", outputPath, inputPath]
                )
            }
            
        case "webp":
            guard let cwebpPath = getBundledToolPath(for: "cwebp") else { return nil }
            let params = EncodingParameters.webpParameters(profile: optimizationProfile, quality: quality)
            return {
                await runCommand(
                    executable: cwebpPath,
                    arguments: params + [inputPath, "-o", outputPath]
                )
            }
            
        case "avif":
            guard let avifencPath = getBundledToolPath(for: "avifenc") else { return nil }
            let params = EncodingParameters.avifParameters(profile: optimizationProfile, quality: quality)
            return {
                await runCommand(
                    executable: avifencPath,
                    arguments: params + [inputPath, outputPath]
                )
            }
            
        case "jxl":
            guard let cjxlPath = getBundledToolPath(for: "cjxl") else { return nil }
            let lossless = quality == 100
            let params = EncodingParameters.jxlParameters(profile: optimizationProfile, quality: quality, lossless: lossless)
            return {
                await runCommand(
                    executable: cjxlPath,
                    arguments: [inputPath, outputPath] + params
                )
            }
            
        default:
            return nil
        }
    }
    
    func decodeToFormat(inputURL: URL, outputPath: String) async -> Bool {
        let inputExt = inputURL.pathExtension.lowercased()
        
        switch inputExt {
        case "jxl":
            guard let djxlPath = getBundledToolPath(for: "djxl") else { return false }
            return await runCommand(executable: djxlPath, arguments: [inputURL.path, outputPath])
            
        case "avif":
            guard let avifdecPath = getBundledToolPath(for: "avifdec") else { return false }
            return await runCommand(executable: avifdecPath, arguments: [inputURL.path, outputPath])
            
        case "webp":
            guard let dwebpPath = getBundledToolPath(for: "dwebp") else { return false }
            return await runCommand(executable: dwebpPath, arguments: [inputURL.path, "-o", outputPath])
        
        default:
            if !FileManager.default.fileExists(atPath: "/usr/bin/sips") {
                SmolrLogger.conversion.error("sips not found on system")
                return false
            }
            SmolrLogger.conversion.debug("Decoding \(inputExt) to PNG using sips")
            return await runCommand(executable: "/usr/bin/sips", arguments: ["-s", "format", "png", inputURL.path, "--out", outputPath])
        }
    }
    
    func runCommand(executable: String, arguments: [String]) async -> Bool {
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments
            
            let errorPipe = Pipe()
            process.standardError = errorPipe
            
            process.terminationHandler = { process in
                if process.terminationStatus != 0 {
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    if let errorString = String(data: errorData, encoding: .utf8) {
                        SmolrLogger.conversion.error("Command failed with status \(process.terminationStatus): \(errorString, privacy: .public)")
                    }
                }
                continuation.resume(returning: process.terminationStatus == 0)
            }
            
            do {
                try process.run()
            } catch {
                SmolrLogger.conversion.error("Failed to run command: \(error.localizedDescription, privacy: .public)")
                continuation.resume(returning: false)
            }
        }
    }
    
    
    // MARK: - View Components

    @ViewBuilder
    private var formatPicker: some View {
        if enabledFormats.count <= 4 {
            Picker("", selection: $outputFormat) {
                ForEach(enabledFormats, id: \.self) { format in
                    Text(FormatConfig.displayName(for: format)).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: calculatePickerWidth())
        } else {
            Picker("", selection: $outputFormat) {
                ForEach(enabledFormats, id: \.self) { format in
                    Text(FormatConfig.displayName(for: format)).tag(format)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
        }
    }
    
    @ViewBuilder
    private var profileWarningBanner: some View {
        if !hideWarnings && (optimizationProfile == .quality || optimizationProfile == .size) {
            MessageBanner(
                icon: "clock.badge.exclamationmark",
                message: "\(optimizationProfile.displayName) profile is enabled. Processing will take longer",
                color: .orange
            )
        }
    }

    // Helper view for consistent message styling
    struct MessageBanner: View {
        let icon: String
        let message: String
        let color: Color
        var onDismiss: (() -> Void)? = nil
        
        var body: some View {
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(color)
                    if let dismiss = onDismiss {
                        Button(action: dismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(color.opacity(0.7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.leading, 8)
                .padding(.trailing, onDismiss == nil ? 8 : 4)
                .padding(.vertical, 4)
                .background(color.opacity(0.1))
                .cornerRadius(4)
                .padding(.trailing, 16)
            }
        }
    }
    
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            if droppedFiles.isEmpty {
                Text(isTargeted ? "Drop images!" : isHovering ? "Click to select images" : "Drag images here")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 4, dash: [14]))
                            .foregroundColor(isTargeted ? accentColor.opacity(0.6) : isHovering ? accentColor.opacity(0.4) : .gray.opacity(0.6))
                    )
                    .onTapGesture {
                        openFilePicker()
                    }
                    .onHover { hovering in
                        isHovering = hovering
                    }
                    .onContinuousHover { phase in
                        switch phase {
                        case .active:
                            NSCursor.pointingHand.push()
                        case .ended:
                            NSCursor.pop()
                        }
                    }
                    .padding()
            } else {
                VStack{
                    List(droppedFiles, id: \.self, selection: $selectedFiles) { file in
                        FileItemRow(file: file, isTargeted: isTargeted, processedFiles: processedFiles, accentColor: accentColor, isSelected: selectedFiles.contains(file))
                            .contentShape(Rectangle())
                                .gesture(
                                    TapGesture(count: 1)
                                        .modifiers(.command)
                                        .onEnded {
                                            toggleSelection(file, multiSelect: true)
                                        }
                                        .exclusively(before:
                                            TapGesture(count: 1)
                                                .onEnded {
                                                    toggleSelection(file, multiSelect: false)
                                                }
                                        )
                                )
                    }
                    .listStyle(.plain)
                    .environment(\.defaultMinListRowHeight, 0)
                    .scrollContentBackground(.hidden)
                    .onDeleteCommand {
                        conversionTask?.cancel()
                        let selectedIDs = Set(selectedFiles.map { $0.id })
                        droppedFiles.removeAll { selectedIDs.contains($0.id) }
                        selectedFiles.removeAll()
                        checkForOutputConflicts()
                    }
                    
                    if totalFilesToConvert > 0 {
                        HStack {
                            Spacer()
                            if totalOriginalBytes > 0 {
                                if totalBytesSaved > 0 {
                                    let percentage = (Double(totalBytesSaved) / Double(totalOriginalBytes)) * 100
                                    Text("Saved \(formatBytes(totalBytesSaved)) out of \(formatBytes(totalOriginalBytes)) (\(String(format: "%.1f",percentage)) %)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    
                                } else if totalBytesSaved < 0 {
                                    Text("Increased by \(formatBytes(abs(totalBytesSaved)))")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                } else {
                                    Text("No change in size (\(formatBytes(totalOriginalBytes)))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Text(" - ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(filesConverted)/\(totalFilesToConvert) files got smolr'd")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.trailing, 16)
                        }
                    }
                    if !warningMessages.isEmpty && !hideWarnings {
                        VStack(alignment: .trailing, spacing: 4) {
                            ForEach(Array(warningMessages.enumerated()), id: \.offset) { index, warning in
                                MessageBanner(
                                    icon: "exclamationmark.triangle.fill",
                                    message: warning,
                                    color: .orange
                                ) {
                                    warningMessages.remove(at: index)
                                }
                            }
                        }
                    }
                    if !errorMessages.isEmpty {
                        VStack(alignment: .trailing, spacing: 4) {
                            ForEach(Array(errorMessages.enumerated()), id: \.offset) { index, error in
                                MessageBanner(
                                    icon: "exclamationmark.triangle.fill",
                                    message: error,
                                    color: .red
                                ) {
                                    errorMessages.remove(at: index)
                                }
                                .onContinuousHover { phase in
                                    switch phase {
                                    case .active: NSCursor.pointingHand.push()
                                    case .ended: NSCursor.pop()
                                    }
                                }
                            }
                        }
                    }
                    profileWarningBanner
                        
                    
                    HStack {
                        Button("Clear All") {
                            conversionTask?.cancel()
                            droppedFiles.removeAll()
                            selectedFiles.removeAll()
                            totalFilesToConvert = 0
                            filesConverted = 0
                            errorMessages.removeAll()
                            warningMessages.removeAll()
                        }
                        .fixedSize()
                        .keyboardShortcut("k", modifiers: .command)
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Group {
                                formatPicker
                            }
                            .onChange(of: outputFormat) { _, _ in
                                checkForOutputConflicts()
                            }
                        
                            HStack(spacing: 4) {
                                Slider(value: Binding(
                                    get: { Double(quality) },
                                    set: { quality = Int($0) }
                                ), in: 50...100, step: 5)
                                .frame(width: 150)
                                
                                Text("\(quality)%")
                                    .frame(width: 36, alignment: .trailing)
                            }
                            Button("Get Smolr") {
                                errorMessages.removeAll()
                                convertFiles()
                            }
                            .buttonStyle(.borderedProminent)
                            .fixedSize()
                            .padding(.leading, 12)
                            .tint(accentColor)
                            .keyboardShortcut(.return, modifiers: .command)
                            
                        }
                    }
                    .padding(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                    
                }
            }
            
        }
        .background(
            Group {
                Button("") {
                    selectedFiles = Set(droppedFiles)
                }
                .keyboardShortcut("a", modifiers: .command)
                .hidden()
                
                Button("") {
                    selectedFiles.removeAll()
                }
                .keyboardShortcut("d", modifiers: .command)
                .hidden()
                
                Button("") {
                    if !selectedFiles.isEmpty {
                        conversionTask?.cancel()
                        let selectedIDs = Set(selectedFiles.map { $0.id })
                        droppedFiles.removeAll { selectedIDs.contains($0.id) }
                        selectedFiles.removeAll()
                        checkForOutputConflicts()
                    }
                }
                .keyboardShortcut(.delete, modifiers: [])
                .hidden()
            }
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted, perform: handleDrop)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenFiles"))) { notification in
            if let urls = notification.object as? [URL] {
                for url in urls {
                    droppedFiles.append(FileItem(url: url))
                }
                checkForOutputConflicts()
                checkDiskSpace()
            }
        }
        .onAppear {
            outputFormat = defaultFormat
        }
        .onChange(of: fileSuffix) { _, _ in
            checkForOutputConflicts()
        }
        .onChange(of: outputFormat) { _, _ in
            checkForOutputConflicts()
        }
        .frame(minWidth: 650, minHeight: 300)
        
    }
}


// MARK: - Preview

#Preview {
    ContentView()
}

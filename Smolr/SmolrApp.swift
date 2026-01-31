// Smolr
// Copyright (c) 2026 Jimmy Houle
// Licensed under BSD 3-Clause License
// See README.md for third-party licenses
import SwiftUI


// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var pendingURLs: [URL] = []
    var openTimer: Timer?
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false 
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        pendingURLs.append(contentsOf: urls)
        
        openTimer?.invalidate()
        openTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            if NSApp.windows.isEmpty || NSApp.keyWindow == nil {
                NSApp.activate(ignoringOtherApps: true)
            }
            
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenFiles"),
                object: self.pendingURLs
            )
            self.pendingURLs.removeAll()
        }
    }
}


// MARK: - Main App

@main
struct SmolrApp: App {
    
    
    // MARK: App Delegate Bridge
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }
    
    
    // MARK: Scene Definition
    
    var body: some Scene {
        Window("Smolr", id: "main") {
            ContentView()
        }
        
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Smolr") {
                    openAboutWindow()
                }
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    checkForUpdates()
                }
                Divider()
            }
            
            
        }
        
        
        Settings {
            PreferencesView()
        }
        
    }
    
    
    // MARK: App Commands
    
    func openAboutWindow() {
        let aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 550),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        aboutWindow.title = "About Smolr"
        aboutWindow.contentView = NSHostingView(rootView: AboutWindowView())
        aboutWindow.center()
        aboutWindow.makeKeyAndOrderFront(nil)
        aboutWindow.isReleasedWhenClosed = false
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func checkForUpdates() {
        UpdateChecker.checkForUpdates { hasUpdate, newVersion, downloadURL in
            if hasUpdate, let version = newVersion, let url = downloadURL {
                let alert = NSAlert()
                alert.messageText = "Update Available"
                alert.informativeText = "Version \(version) is available. Would you like to download it?"
                alert.addButton(withTitle: "Download")
                alert.addButton(withTitle: "Later")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(url)
                }
            } else {
                let alert = NSAlert()
                alert.messageText = "You're Up to Date"
                alert.informativeText = "Smolr \(UpdateChecker.currentVersion) is the latest version."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
}

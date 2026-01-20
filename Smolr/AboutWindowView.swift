// Smolr
// Copyright (c) 2026 Jimmy Houle
// Licensed under BSD 3-Clause License
// See README.md for third-party licenses
import SwiftUI

struct AboutWindowView: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: 12) {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Smolr")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Modern image compression and conversion")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            Divider()
            
            // Credits section
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Built With")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    ToolCredit(name: "WebP", url: "https://developers.google.com/speed/webp")
                    ToolCredit(name: "AVIF (libavif)", url: "https://github.com/AOMediaCodec/libavif")
                    ToolCredit(name: "JPEG XL (libjxl)", url: "https://github.com/libjxl/libjxl")
                    ToolCredit(name: "MozJPEG", url: "https://github.com/mozilla/mozjpeg")
                    ToolCredit(name: "oxipng", url: "https://github.com/shssoichiro/oxipng")
                    ToolCredit(name: "pngquant", url: "https://pngquant.org")
                    ToolCredit(name: "Gifsicle", url: "https://www.lcdf.org/gifsicle")
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
            .frame(height: 200)
            
            Divider()
            
            VStack(spacing: 12) {
                Text("Created by Jimmy Houle")
                    .font(.subheadline)
                
                HStack(spacing: 20) {
                    Button(action: {
                        openURL(URL(string: "https://github.com/jimjimca/Smolr")!)
                    }) {
                        Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    Button(action: {
                        openURL(URL(string: "https://buymeacoffee.com/jimjimca")!)
                    }) {
                        Label("Buy Me a Coffee", systemImage: "cup.and.saucer.fill")
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 20)
        }
        .frame(width: 450, height: 550)
    }
}

struct ToolCredit: View {
    let name: String
    let url: String
    @Environment(\.openURL) var openURL
    
    var body: some View {
        HStack {
            Text("•")
                .foregroundColor(.secondary)
            Button(action: {
                openURL(URL(string: url)!)
            }) {
                Text(name)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .font(.caption)
    }
}

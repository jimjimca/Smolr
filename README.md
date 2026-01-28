# Smolr

Compress and convert images on macOS. 
Supports modern formats like WebP, AVIF, and JPEG XL.

## What it does

Drop in your images, choose a format (or keep the original), adjust quality, and convert. That's it.

Optimisation with PNG, JPEG, GIF, WebP, AVIF, and JXL.
Conversion to WebP, AVIF, and JXL.

## Requirements

- macOS 14.0 (Sonoma) or later
- Works natively on both Apple Silicon (M1/M2/M3/M4) and Intel Macs

## Features

- Convert between WebP, AVIF, JXL, PNG, JPEG, GIF
- Optimize files without format conversion
- Batch process multiple images
- Quality slider (50-100%)
- All processing local - nothing leaves your machine
- Self-contained - no Homebrew or external dependencies needed
- Strips EXIF data during conversion
- Preference settings (suffix, default quality, default format, etc.)

## Download

**Free:** [GitHub Releases](https://github.com/jimjimca/Smolr/releases)

**Support development:** [Official Website](https://smolr.io) (pay what you want, $0+ accepted)

Since the app code is not yet signed, on the fisrt launch you might need to do the following : 
1. Drag Smolr.app into your Applications folder.
2. If you see the message: “Smolr.app can’t be opened because it was not downloaded from the App Store.” click OK.
3. Open System Settings → Privacy & Security.
4. Scroll to the bottom where you’ll see: “Smolr.app was blocked to protect your Mac.”
5. Click Open Anyway.
6. If prompted with “Smolr.app is not from the App Store. Are you sure you want to open it?”, click Open.

## Building

```bash
git clone https://github.com/jimjimca/Smolr.git
cd Smolr/Smolr
open Smolr.xcodeproj
```

All encoding tools and libraries are included in the repo.

## Keyboard shortcuts

- `⌘ Return` - Start conversion
- `⌘ K` - Clear all files
- `⌘ A` - Select all
- `⌘ D` - Deselect all
- `Delete` - Remove selected files

## Technical Details

Smolr bundles many encoding/decoding tools (see credits below) as universal binaries, ensuring native performance on both Apple Silicon and Intel Macs. All dependencies (29 dylibs + 12 tools) are included within the app bundle. No system dependencies required.

When converting between incompatible formats (e.g., JXL → WebP), files are decoded to PNG then re-encoded. This causes some generation loss - use original source files when possible.


## Credits / Third-Party Libraries

Built with bundled open source tools:

- [WebP](https://developers.google.com/speed/webp) - Google
- [libavif](https://github.com/AOMediaCodec/libavif) - AOMediaCodec
- [libjxl](https://github.com/libjxl/libjxl) - JPEG XL reference implementation
- [MozJPEG](https://github.com/mozilla/mozjpeg) - Mozilla
- [oxipng](https://github.com/shssoichiro/oxipng)
- [pngquant](https://pngquant.org)
- [Gifsicle](https://www.lcdf.org/gifsicle)

## License

BSD 3-Clause License - see LICENSE file

---

Made by [Jimmy Houle](https://github.com/jimjimca)
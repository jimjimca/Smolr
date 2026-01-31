# Smolr

Compress and convert images on macOS. 
Supports modern formats like WebP, AVIF, and JPEG XL.

## What it does

Drop in your images, choose a format (or keep the original), adjust quality, and convert. That's it.

Optimisation with PNG, JPEG, GIF, WebP, AVIF, and JXL.
Conversion to WebP, AVIF, JXL, PNG, and JPEG.

## Requirements

- macOS 14.0 (Sonoma) or later
- Works natively on both Apple Silicon (M1/M2/M3/M4) and Intel Macs

## Features

- Convert between WebP, AVIF, JXL, PNG, JPEG, GIF
- Optimize files without format conversion
- Drag and drop individual files or entire folders
- Batch process multiple images
- Quality slider (50-100%)
- Optimization profiles: Fast, Balanced, Quality, Size
- All processing local - nothing leaves your machine
- Self-contained - no Homebrew or external dependencies needed
- Strips EXIF data during conversion
- Preference settings (suffix, default quality, default format, optimization profile, etc.)

## Usage

### Converting and optimizing

1. Drop your images or a folder into Smolr
2. Choose a target format from the picker at the bottom (or keep "Original" to optimize without converting)
3. Adjust the quality slider (50–100%)
4. Click **Get Smolr** (or press `⌘ Return`)

Output files are saved next to the originals with a configurable suffix (default: `_smolr`).

### Optimization Profiles

Smolr includes four optimization profiles that control how aggressively each encoder processes your images. Select your profile in **Settings → Optimization Profile**.

**Fast** | Fastest | Quick processing with basic optimization. Best for previews or when speed matters most.
**Balanced** | Default | Good balance between speed and compression. Recommended for most use cases.
**Quality** | Slower | Maximizes visual quality. Encoders run at highest effort — expect noticeably longer processing times.
**Size** | Slower | Minimizes file size. Most aggressive compression settings. Strips all metadata.

The **Quality** and **Size** profiles can be 10–20× slower than **Fast**, especially on large files.

The quality slider (50–100%) is always respected regardless of profile. Profiles tune the *encoding parameters*, not the quality level.

### Customizing the format picker

By default, Smolr shows **Original, WebP, AVIF, and JXL** in the format picker. You can customize which formats are available in settings (**Default Format**).

You can also enable **PNG** and **JPEG** as conversion targets this way, not just as optimization formats.

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

GIF is supported for optimization only. Conversion *to* GIF from other formats is not supported.


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
<div align="center">
  <img src="Docs/banner.png" alt="PhotoSorterCore Banner" width="100%">
  
  <h1>PhotoSorterCore</h1>
  
  <p>
    <strong>A powerful Swift library for organizing, sorting, and managing photo and video collections on macOS</strong>
  </p>
  
  <p>
    <a href="#features">Features</a> •
    <a href="#installation">Installation</a> •
    <a href="#quick-start">Quick Start</a> •
    <a href="Docs/">Documentation</a>
  </p>
  
  <p>
    <img src="https://img.shields.io/badge/Platform-macOS%2015.0+-blue.svg" alt="Platform">
    <img src="https://img.shields.io/badge/Swift-6.0+-orange.svg" alt="Swift">
    <img src="https://img.shields.io/badge/Xcode-16.0+-blue.svg" alt="Xcode">
    <img src="https://img.shields.io/badge/SPM-compatible-brightgreen.svg" alt="SPM">
    <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  </p>
  
  <p>
    <a href="README-ru.md">Русская версия</a>
  </p>
</div>

---

PhotoSorterCore provides comprehensive functionality for metadata handling, date fixing, format conversion, and intelligent file organization.

## Features

- **Smart Photo & Video Sorting** - Automatically organize media files by date into structured folder hierarchies (Year/Month)
- **Metadata Management** - Extract and fix EXIF/metadata dates from photos and videos
- **Format Conversion** - Convert PNG and DNG files to HEIC format with quality preservation
- **Date Fixing Tools** - Fix incorrect or missing dates in file metadata
- **Flexible Renaming** - Rename files with customizable date format patterns
- **Batch Processing** - Process entire folders with progress tracking and error handling
- **Security-Scoped Resources** - Full support for macOS sandboxing and security-scoped URLs

## Requirements

- macOS 15.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add PhotoSorterCore to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/PhotoSorterCore.git", from: "1.0.0")
]
```

Or add it in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Select version and add to your target

## Quick Start

### Basic Photo Sorting

```swift
import PhotoSorterCore

// Configure the sorter
let config = SorterEngine.Configure(
    inputFolder: inputURL,
    outputFolder: outputURL,
    options: [.createFolders, .renameFiles],
    dateFormat: "YYYY-MM-DD HH-mm"
)

// Create and run the sorter
let sorter = SorterEngine(configure: config)

let result = try await sorter.run(
    progressHandler: { progress in
        switch progress {
        case .started:
            print("Sorting started...")
        case .fileProcessed(let source, let target):
            print("Processed: \(source) → \(target)")
        case .completed(let count):
            print("Completed! Processed \(count) files")
        default:
            break
        }
    },
    errorHandler: { error in
        print("Error: \(error)")
    }
)
```

### Convert Images to HEIC

```swift
import PhotoSorterCore

let converter = UnifiedConvertManager()

await converter.convertToHEIC(
    from: .png,  // or .dng
    folderURL: folderURL,
    deleteOriginalFile: false,
    stateHandler: { state in
        print("Conversion state: \(state)")
    }
)
```

### Fix File Metadata Dates

```swift
import PhotoSorterCore

let fixDateTool = FixDateTool()

// Fix dates by extracting from metadata
try fixDateTool.fixDatesIn(folderURL: folderURL) { error in
    print("Date fixing error: \(error)")
}

// Or set a specific date for all files
try fixDateTool.forceSetDate(
    with: specificDate,
    forFolder: folderURL
) { error in
    print("Date setting error: \(error)")
}
```

## Main Components

### SorterEngine
The core engine for sorting and organizing media files. Supports multiple options:
- `createFolders` - Create Year/Month folder structure
- `renameFiles` - Rename files with date format
- `fixMetadata` - Fix file metadata during sorting
- `forceUpdateDate` - Set specific date for all files

### UnifiedConvertManager
Unified image format converter supporting:
- PNG to HEIC conversion
- DNG (RAW) to HEIC conversion
- Preserves file attributes and metadata
- Configurable quality settings

### FixDateTool
Advanced date fixing functionality:
- Extract minimum date from all metadata fields
- Fix EXIF/metadata dates
- Set content creation dates
- Support for photos and videos

## Documentation

For detailed documentation, examples, and advanced usage:

- [API Documentation](Docs/) - Complete API reference
- [Examples](Docs/EXAMPLES.md) - Code examples and use cases
- [Migration Guide](Docs/MIGRATION_GUIDE.md) - Upgrading from older versions
- [Changelog](Docs/CHANGELOG.md) - Version history and changes

## Error Handling

PhotoSorterCore provides comprehensive error handling with detailed error types:

```swift
do {
    let result = try await sorter.run(
        progressHandler: { progress in },
        errorHandler: { error in
            // Handle non-critical file processing errors
            switch error {
            case .invalidDate(let path, let date):
                print("Invalid date in \(path): \(date)")
            case .moveFailed(let source, let destination, let reason):
                print("Move failed: \(reason)")
            default:
                print("Processing error: \(error)")
            }
        }
    )
} catch let error as SorterError {
    // Handle critical errors
    switch error {
    case .permissionDenied:
        print("Permission denied")
    case .folderNotAccessible(let path):
        print("Cannot access folder: \(path)")
    case .cancelled:
        print("Operation cancelled")
    }
}
```

## Testing

PhotoSorterCore includes comprehensive test coverage with dependency injection support:

```swift
// All major components support dependency injection for testing
let mockDateExtractor = MockDateExtractor()
let mockCommandExecutor = MockSystemCommandExecutor()

let fixDateTool = FixDateTool(
    dateExtractor: mockDateExtractor,
    commandExecutor: mockCommandExecutor
)
```

Run tests:
```bash
swift test
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

PhotoSorterCore is released under the MIT License.

## Author

Andrey Torlopov — torlopov.mail@ya.ru

## Support

For bug reports and feature requests, please open an issue on GitHub.

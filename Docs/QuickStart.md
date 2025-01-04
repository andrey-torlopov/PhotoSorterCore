# Quick Start Guide

This guide will help you get started with PhotoSorterCore in just a few minutes.

## Installation

Add PhotoSorterCore to your project using Swift Package Manager:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/yourusername/PhotoSorterCore.git", from: "1.0.0")
]
```

## Your First Photo Sorter

### 1. Import the Library

```swift
import PhotoSorterCore
```

### 2. Configure the Sorter

```swift
// Define input and output folders
let inputFolder = URL(fileURLWithPath: "/path/to/unsorted/photos")
let outputFolder = URL(fileURLWithPath: "/path/to/sorted/photos")

// Create configuration
let config = SorterEngine.Configure(
    inputFolder: inputFolder,
    outputFolder: outputFolder,
    options: [.createFolders, .renameFiles],
    dateFormat: "YYYY-MM-DD HH-mm"
)
```

### 3. Create and Run the Sorter

```swift
let sorter = SorterEngine(configure: config)

Task {
    do {
        let result = try await sorter.run(
            progressHandler: { progress in
                switch progress {
                case .started:
                    print("🚀 Sorting started...")
                case .fileProcessed(let source, let target):
                    print("✅ Processed: \(source.lastPathComponent)")
                case .folderCreated(let name):
                    print("📁 Created folder: \(name)")
                case .completed(let count):
                    print("🎉 Completed! Processed \(count) files")
                }
            },
            errorHandler: { error in
                print("⚠️ Error: \(error)")
            }
        )
        
        print("Total processed: \(result.processedCount)")
        print("Total errors: \(result.errors.count)")
    } catch {
        print("❌ Critical error: \(error)")
    }
}
```

## Common Options

### Sort Without Renaming

```swift
let config = SorterEngine.Configure(
    inputFolder: inputFolder,
    outputFolder: outputFolder,
    options: [.createFolders],  // Only create folders, keep original names
    dateFormat: "YYYY-MM-DD"
)
```

### Fix Metadata While Sorting

```swift
let config = SorterEngine.Configure(
    inputFolder: inputFolder,
    outputFolder: outputFolder,
    options: [.createFolders, .renameFiles, .fixMetadata],  // Fix dates too
    dateFormat: "YYYY-MM-DD HH-mm"
)
```

### Set Custom Date for All Files

```swift
let customDate = Date() // or any specific date
let config = SorterEngine.Configure(
    inputFolder: inputFolder,
    outputFolder: outputFolder,
    options: [.createFolders, .forceUpdateDate],
    dateFormat: "YYYY-MM-DD HH-mm",
    concreteDate: customDate
)
```

## Date Format Patterns

PhotoSorterCore supports flexible date formatting:

| Pattern | Description | Example |
|---------|-------------|---------|
| `YYYY` or `yyyy` | 4-digit year | 2024 |
| `MM` | 2-digit month | 03 |
| `DD` or `dd` | 2-digit day | 15 |
| `HH` or `hh` | 2-digit hour | 14 |
| `mm` | 2-digit minute | 30 |

### Example Formats

```swift
// "2024-03-15 14-30.jpg"
dateFormat: "YYYY-MM-DD HH-mm"

// "2024.03.15_14.30.jpg"
dateFormat: "YYYY.MM.DD_HH.mm"

// "20240315_1430.jpg"
dateFormat: "YYYYMMdd_HHmm"
```

## Output Structure

With `createFolders` option enabled, files will be organized as:

```
outputFolder/
├── Photos/
│   ├── 2024/
│   │   ├── 01/
│   │   │   ├── 2024-01-15 10-30.jpg
│   │   │   └── 2024-01-20 14-45.jpg
│   │   └── 02/
│   │       └── 2024-02-10 16-20.jpg
└── Videos/
    └── 2024/
        └── 03/
            └── 2024-03-05 18-00.mov
```

## Next Steps

Now that you've sorted your first photos, explore more features:

- [Converting Formats](guides/ConvertingFormats.md) - Convert images to HEIC
- [Fixing Dates](guides/FixingDates.md) - Fix metadata dates
- [Error Handling](guides/ErrorHandling.md) - Handle errors properly
- [Advanced Configuration](guides/AdvancedConfiguration.md) - Advanced usage

## Common Issues

### Permission Denied

Make sure your app has proper permissions to access the folders:

```swift
// For sandboxed apps, use security-scoped bookmarks
let inputFolder = // ... get from user with NSOpenPanel
guard inputFolder.startAccessingSecurityScopedResource() else {
    print("Cannot access folder")
    return
}
defer { inputFolder.stopAccessingSecurityScopedResource() }
```

### No Files Processed

Check that:
1. Input folder contains valid media files (jpg, png, heic, mov, mp4, etc.)
2. Files have readable metadata
3. Output folder is writable

See [Error Handling Guide](guides/ErrorHandling.md) for more troubleshooting.

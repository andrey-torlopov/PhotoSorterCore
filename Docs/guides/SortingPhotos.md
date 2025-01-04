# Sorting Photos Guide

Complete guide to sorting and organizing photos and videos with PhotoSorterCore.

## Table of Contents

- [Overview](#overview)
- [Basic Sorting](#basic-sorting)
- [Configuration Options](#configuration-options)
- [Date Formats](#date-formats)
- [Output Structure](#output-structure)
- [Advanced Usage](#advanced-usage)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)

## Overview

The SorterEngine is the main component for organizing media files. It can:

- Sort files by date into Year/Month folders
- Rename files with customizable date patterns
- Fix metadata dates during sorting
- Handle both photos and videos
- Process thousands of files efficiently

## Basic Sorting

### Simple Sort with Folders

```swift
import PhotoSorterCore

let config = SorterEngine.Configure(
    inputFolder: URL(fileURLWithPath: "/path/to/photos"),
    outputFolder: URL(fileURLWithPath: "/path/to/sorted"),
    options: [.createFolders],
    dateFormat: "YYYY-MM-DD"
)

let sorter = SorterEngine(configure: config)

let result = try await sorter.run(
    progressHandler: { progress in
        print("Progress: \(progress)")
    },
    errorHandler: { error in
        print("Error: \(error)")
    }
)
```

### Sort with Renaming

```swift
let config = SorterEngine.Configure(
    inputFolder: inputURL,
    outputFolder: outputURL,
    options: [.createFolders, .renameFiles],
    dateFormat: "YYYY-MM-DD HH-mm"
)
```

## Configuration Options

### Available Options

#### `.createFolders`
Creates Year/Month folder structure:
```
Photos/
  2024/
    01/
    02/
Videos/
  2024/
    01/
```

#### `.renameFiles`
Renames files according to `dateFormat`:
```swift
// Input: IMG_1234.jpg
// Output: 2024-01-15 14-30.jpg
options: [.renameFiles]
dateFormat: "YYYY-MM-DD HH-mm"
```

#### `.fixMetadata`
Fixes file metadata dates during sorting:
```swift
options: [.createFolders, .fixMetadata]
```

This extracts the earliest valid date from metadata and updates all date fields.

#### `.forceUpdateDate`
Sets a specific date for all files:
```swift
let specificDate = Calendar.current.date(from: DateComponents(
    year: 2024, month: 1, day: 15
))!

let config = SorterEngine.Configure(
    inputFolder: inputURL,
    outputFolder: outputURL,
    options: [.forceUpdateDate],
    dateFormat: "YYYY-MM-DD",
    concreteDate: specificDate
)
```

### Combining Options

```swift
// Full featured: organize, rename, and fix dates
options: [.createFolders, .renameFiles, .fixMetadata]

// Just organize without changing files
options: [.createFolders]

// Rename in place (no folder structure)
options: [.renameFiles]
```

## Date Formats

### Format Tokens

| Token | Description | Example |
|-------|-------------|---------|
| `YYYY` or `yyyy` | 4-digit year | 2024 |
| `MM` | 2-digit month | 03 |
| `DD` or `dd` | 2-digit day | 15 |
| `HH` or `hh` | 2-digit hour | 14 |
| `mm` | 2-digit minute | 30 |

### Common Patterns

```swift
// Standard: 2024-01-15 14-30.jpg
dateFormat: "YYYY-MM-DD HH-mm"

// Compact: 20240115_1430.jpg
dateFormat: "YYYYMMdd_HHmm"

// Dotted: 2024.01.15_14.30.jpg
dateFormat: "YYYY.MM.DD_HH.mm"

// Date only: 2024-01-15.jpg
dateFormat: "YYYY-MM-DD"
```

## Output Structure

### With `.createFolders`

```
outputFolder/
├── Photos/
│   ├── 2024/
│   │   ├── 01/
│   │   │   ├── 2024-01-15 10-30.jpg
│   │   │   ├── 2024-01-15 10-31.jpg
│   │   │   └── 2024-01-20 14-45.jpg
│   │   ├── 02/
│   │   │   └── 2024-02-10 16-20.jpg
│   │   └── 03/
│   │       └── 2024-03-05 12-15.jpg
└── Videos/
    └── 2024/
        ├── 01/
        │   └── 2024-01-15 10-30.mov
        └── 03/
            └── 2024-03-05 18-00.mp4
```

### Without `.createFolders`

All files go to the output folder root:
```
outputFolder/
├── 2024-01-15 10-30.jpg
├── 2024-01-15 10-31.jpg
├── 2024-01-20 14-45.jpg
└── 2024-01-15 10-30.mov
```

## Advanced Usage

### With Progress Tracking

```swift
var processedCount = 0
var folderCount = 0

let result = try await sorter.run(
    progressHandler: { progress in
        switch progress {
        case .started:
            print("Starting sort operation...")
            
        case .folderCreated(let name):
            folderCount += 1
            print("Created folder: \(name)")
            
        case .fileProcessed(let source, let target):
            processedCount += 1
            print("[\(processedCount)] \(URL(fileURLWithPath: source).lastPathComponent)")
            print("  → \(target)")
            
        case .completed(let count):
            print("\n✅ Completed!")
            print("Processed: \(count) files")
            print("Created: \(folderCount) folders")
        }
    },
    errorHandler: { error in
        print("⚠️ Error: \(error)")
    }
)
```

### With Error Collection

```swift
var errors: [FileProcessingError] = []

let result = try await sorter.run(
    progressHandler: { _ in },
    errorHandler: { error in
        errors.append(error)
    }
)

// Review errors after completion
print("Total errors: \(result.errors.count)")
for error in result.errors {
    switch error {
    case .invalidDate(let path, let dateString):
        print("Invalid date '\(dateString)' in: \(path)")
    case .moveFailed(let source, let dest, let reason):
        print("Failed to move \(source): \(reason)")
    default:
        print("Error: \(error)")
    }
}
```

### With Cancellation Support

```swift
let task = Task {
    do {
        let result = try await sorter.run(
            progressHandler: { _ in },
            errorHandler: { _ in }
        )
        return result
    } catch let error as SorterError {
        if case .cancelled = error {
            print("Operation was cancelled")
        }
        throw error
    }
}

// Cancel if needed
task.cancel()
```

## Error Handling

### Critical Errors (Thrown)

```swift
do {
    let result = try await sorter.run(...)
} catch SorterError.permissionDenied {
    print("Access denied to folders")
} catch SorterError.folderNotAccessible(let path) {
    print("Cannot access: \(path)")
} catch SorterError.folderCreationFailed(let path) {
    print("Cannot create: \(path)")
} catch SorterError.cancelled {
    print("Operation cancelled by user")
}
```

### File Processing Errors (Callback)

```swift
errorHandler: { error in
    switch error {
    case .invalidDate(let filePath, let dateString):
        // File has invalid date in metadata or filename
        
    case .moveFailed(let source, let destination, let reason):
        // Could not move file
        
    case .metadataUpdateFailed(let filePath, let folderPath, let reason):
        // Metadata fix failed (if using .fixMetadata)
        
    case .dateUpdateFailed(let fileURL, let reason):
        // Date update failed
        
    default:
        print("Other error: \(error)")
    }
}
```

## Best Practices

### 1. Test with Sample Data First

```swift
// Create test folder with a few files
let testInput = URL(fileURLWithPath: "/path/to/test/input")
let testOutput = URL(fileURLWithPath: "/path/to/test/output")

// Test configuration
let config = SorterEngine.Configure(
    inputFolder: testInput,
    outputFolder: testOutput,
    options: [.createFolders, .renameFiles],
    dateFormat: "YYYY-MM-DD HH-mm"
)

// Run test
let result = try await SorterEngine(configure: config).run(...)
```

### 2. Use Security-Scoped Resources

For sandboxed apps:

```swift
guard inputFolder.startAccessingSecurityScopedResource() else {
    throw NSError(domain: "MyApp", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "Cannot access input folder"
    ])
}
defer { inputFolder.stopAccessingSecurityScopedResource() }

guard outputFolder.startAccessingSecurityScopedResource() else {
    inputFolder.stopAccessingSecurityScopedResource()
    throw NSError(domain: "MyApp", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "Cannot access output folder"
    ])
}
defer { outputFolder.stopAccessingSecurityScopedResource() }

let result = try await sorter.run(...)
```

### 3. Monitor Progress in UI

```swift
@MainActor
class SortViewModel: ObservableObject {
    @Published var progress: String = ""
    @Published var processedCount: Int = 0
    
    func sort() async throws {
        let result = try await sorter.run(
            progressHandler: { [weak self] progress in
                Task { @MainActor in
                    switch progress {
                    case .fileProcessed(_, _):
                        self?.processedCount += 1
                    case .completed(let count):
                        self?.progress = "Completed: \(count) files"
                    default:
                        break
                    }
                }
            },
            errorHandler: { error in
                print("Error: \(error)")
            }
        )
    }
}
```

### 4. Handle Duplicate Filenames

PhotoSorterCore automatically handles duplicates:

```swift
// If target file exists:
// 2024-01-15 10-30.jpg
// 2024-01-15 10-30 (1).jpg
// 2024-01-15 10-30 (2).jpg
```

### 5. Preserve Original Files

Always keep backups when sorting important files:

```swift
// Option 1: Sort to different folder (recommended)
let input = URL(fileURLWithPath: "/original/photos")
let output = URL(fileURLWithPath: "/sorted/photos")

// Option 2: Copy before sorting
try FileManager.default.copyItem(at: input, to: backup)
```

## Performance Tips

1. **Large Collections**: For 10,000+ files, process in batches
2. **Network Drives**: Slower; prefer local drives
3. **SSD vs HDD**: Significant speed difference
4. **Metadata Fixing**: Adds overhead; use only when needed

## Next Steps

- [Converting Formats](ConvertingFormats.md) - Convert to HEIC
- [Fixing Dates](FixingDates.md) - Fix metadata dates
- [Error Handling](ErrorHandling.md) - Advanced error handling
- [API Reference](../api/SorterEngine.md) - Complete API docs

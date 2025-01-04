# Basic Concepts

This guide introduces the core concepts and architecture of PhotoSorterCore.

## Overview

PhotoSorterCore is built around three main components:

1. **SorterEngine** - Organizes and sorts media files
2. **UnifiedConvertManager** - Converts image formats
3. **FixDateTool** - Manages file dates and metadata

## Architecture

```
┌─────────────────────────────────────────┐
│         Your Application                │
└───────────────┬─────────────────────────┘
                │
        ┌───────┴────────┐
        │                │
┌───────▼──────┐  ┌──────▼──────────┐
│ SorterEngine │  │ UnifiedConvert  │
│              │  │    Manager      │
└───────┬──────┘  └──────┬──────────┘
        │                │
        └────┬───────────┘
             │
      ┌──────▼──────────┐
      │   FixDateTool   │
      └─────────────────┘
             │
      ┌──────▼──────────┐
      │  Core Services  │
      │  - DateExtractor│
      │  - FileAnalysis │
      │  - PhotosHelper │
      └─────────────────┘
```

## Core Components

### 1. SorterEngine

The main engine for organizing media files. It processes files through several stages:

**Configuration:**
```swift
let config = SorterEngine.Configure(
    inputFolder: URL,      // Source folder
    outputFolder: URL,     // Destination folder
    options: Set<Option>,  // Processing options
    dateFormat: String,    // Date format pattern
    concreteDate: Date?    // Optional specific date
)
```

**Options:**
- `.createFolders` - Create Year/Month folder structure
- `.renameFiles` - Rename files with date format
- `.fixMetadata` - Fix file metadata during sorting
- `.forceUpdateDate` - Set specific date for all files

**Processing Flow:**
```
Input Files → Analysis → Date Extraction → Folder Creation → Rename → Move → Output
```

### 2. UnifiedConvertManager

Handles image format conversions with a unified interface.

**Supported Conversions:**
- PNG → HEIC
- DNG (RAW) → HEIC

**Features:**
- Quality preservation
- Metadata retention
- Batch processing
- Optional deletion of originals

**Conversion Flow:**
```
Source File → Load Image → Convert to HEIC → Save → Copy Attributes → (Delete Original)
```

### 3. FixDateTool

Manages file dates and metadata with multiple strategies.

**Date Sources (Priority Order):**
1. EXIF DateTimeOriginal
2. EXIF DateTimeDigitized
3. File Creation Date
4. File Modification Date
5. Spotlight Metadata

**Operations:**
- Extract minimum date from all sources
- Fix metadata dates
- Set specific dates
- Update file system attributes

## Data Flow

### Sorting Operation

```
┌─────────────┐
│ Input Files │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│ FileAnalysis     │ ← Extract metadata
│ Service          │ ← Detect file type
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Date Extraction  │ ← Get date from metadata
│                  │ ← Validate date
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ (Optional)       │
│ Fix Metadata     │ ← Fix dates if needed
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Folder Creation  │ ← Create Year/Month structure
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ File Naming      │ ← Generate target filename
│                  │ ← Handle duplicates
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Move File        │ ← Move to target location
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Progress Report  │ ← Notify completion
└──────────────────┘
```

## File Analysis

PhotoSorterCore analyzes each file to determine:

**File Type Detection:**
- Photos vs. Videos
- Supported format detection
- File extension validation

**Date Information:**
```swift
struct FileAnalysisResult {
    let fileInfo: FileInfo              // Path, extension, type
    let date: Date?                     // Extracted date
    let dateComponents: DateComponents? // Year, month, day, etc.
    let isVideo: Bool                   // Photo or video
    let isFileNameDateValid: Bool       // Valid date in filename
    let shouldIgnore: Bool              // Skip processing
    let dateDescription: String         // Human-readable date
}
```

## Error Handling Strategy

PhotoSorterCore uses a two-tier error system:

### Critical Errors (Thrown)
These stop the entire operation:
```swift
enum SorterError: Error {
    case permissionDenied
    case folderNotAccessible(path: String)
    case folderCreationFailed(path: String)
    case cancelled
}
```

### File Processing Errors (Collected)
These are reported but don't stop processing:
```swift
enum FileProcessingError: Error {
    case invalidDate(filePath: String, dateString: String)
    case moveFailed(source: String, destination: String, reason: String)
    case metadataError(filePath: String, error: String)
    case dateUpdateFailed(fileURL: URL, reason: String)
    // ... more specific errors
}
```

**Usage:**
```swift
try await sorter.run(
    progressHandler: { progress in },
    errorHandler: { error in
        // Handle individual file errors
        // Operation continues
    }
) // Throws critical errors only
```

## Progress Tracking

Monitor operation progress with detailed events:

```swift
enum SorterProgress {
    case started
    case fileProcessed(sourcePath: String, targetPath: String)
    case folderCreated(name: String)
    case completed(processedCount: Int)
}
```

## Dependency Injection

All components support dependency injection for testing:

```swift
// Production
let sorter = SorterEngine(configure: config)

// Testing
let sorter = SorterEngine(
    configure: config,
    fixDateTool: MockFixDateTool(),
    photosHelper: MockPhotosHelper(),
    fileAnalysisService: MockFileAnalysisService()
)
```

## Thread Safety

PhotoSorterCore is designed for concurrent use:

- All public APIs are `async` and support cancellation
- Internal state is protected with actors where needed
- File operations are serialized to prevent conflicts
- Progress and error handlers are called on appropriate queues

## Supported File Types

### Photos
- JPEG (.jpg, .jpeg)
- PNG (.png)
- HEIC (.heic)
- TIFF (.tiff, .tif)
- DNG (.dng)
- RAW formats (.cr2, .nef, .arw, etc.)

### Videos
- MOV (.mov)
- MP4 (.mp4)
- M4V (.m4v)
- AVI (.avi)

## Best Practices

1. **Always use security-scoped resources** for sandboxed apps
2. **Handle both error types** - critical (thrown) and file-level (callback)
3. **Monitor progress** to provide user feedback
4. **Test with sample data** before processing important files
5. **Keep backups** of original files when possible

## Next Steps

- [Quick Start](QuickStart.md) - Start using the library
- [Sorting Photos Guide](guides/SortingPhotos.md) - Detailed sorting guide
- [API Reference](api/) - Complete API documentation

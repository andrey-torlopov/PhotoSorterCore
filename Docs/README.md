# PhotoSorterCore Documentation

Welcome to the PhotoSorterCore documentation. This directory contains comprehensive guides and references for using the library.

## Documentation Index

### Getting Started
- [Quick Start Guide](QuickStart.md) - Get up and running quickly
- [Installation](Installation.md) - Detailed installation instructions
- [Basic Concepts](BasicConcepts.md) - Core concepts and architecture

### Guides
- [Sorting Photos](guides/SortingPhotos.md) - Complete guide to photo sorting
- [Converting Formats](guides/ConvertingFormats.md) - Image format conversion
- [Fixing Dates](guides/FixingDates.md) - Working with file dates and metadata
- [Error Handling](guides/ErrorHandling.md) - Handling errors effectively
- [Advanced Configuration](guides/AdvancedConfiguration.md) - Advanced usage patterns

### API Reference
- [SorterEngine API](api/SorterEngine.md) - Main sorting engine
- [UnifiedConvertManager API](api/UnifiedConvertManager.md) - Format conversion
- [FixDateTool API](api/FixDateTool.md) - Date fixing functionality
- [Error Types](api/ErrorTypes.md) - Complete error reference

### Migration & Changes
- [Migration Guide](MIGRATION_GUIDE.md) - Upgrading from previous versions
- [Changelog](CHANGELOG.md) - Version history
- [Examples](EXAMPLES.md) - Code examples and snippets

### Development
- [Contributing](Contributing.md) - How to contribute
- [Testing](Testing.md) - Running and writing tests
- [Architecture](Architecture.md) - Library architecture overview

## Quick Links

### Common Tasks

**Sort photos by date:**
```swift
let config = SorterEngine.Configure(
    inputFolder: inputURL,
    outputFolder: outputURL,
    options: [.createFolders, .renameFiles],
    dateFormat: "YYYY-MM-DD HH-mm"
)
let sorter = SorterEngine(configure: config)
try await sorter.run(progressHandler: { _ in }, errorHandler: { _ in })
```

**Convert PNG to HEIC:**
```swift
let converter = UnifiedConvertManager()
await converter.convertToHEIC(from: .png, folderURL: folderURL, deleteOriginalFile: false) { _ in }
```

**Fix file dates:**
```swift
let fixDateTool = FixDateTool()
try fixDateTool.fixDatesIn(folderURL: folderURL) { error in }
```

## Support

- **Issues**: Report bugs and request features on [GitHub Issues](https://github.com/yourusername/PhotoSorterCore/issues)
- **Discussions**: Ask questions in [GitHub Discussions](https://github.com/yourusername/PhotoSorterCore/discussions)

## Contributing

We welcome contributions! Please see our [Contributing Guide](Contributing.md) for details.

## License

[Your License]

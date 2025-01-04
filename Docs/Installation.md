# Installation Guide

This guide covers different ways to install and integrate PhotoSorterCore into your project.

## Requirements

Before installing PhotoSorterCore, ensure your development environment meets these requirements:

- **macOS**: 15.0 or later
- **Swift**: 6.0 or later
- **Xcode**: 16.0 or later

## Swift Package Manager (Recommended)

Swift Package Manager is the recommended way to integrate PhotoSorterCore.

### Using Package.swift

Add PhotoSorterCore as a dependency in your `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YourProject",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(
            url: "https://github.com/yourusername/PhotoSorterCore.git",
            from: "1.0.0"
        )
    ],
    targets: [
        .target(
            name: "YourProject",
            dependencies: ["PhotoSorterCore"]
        )
    ]
)
```

Then run:
```bash
swift package update
```

### Using Xcode

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies...**
3. Enter the repository URL: `https://github.com/yourusername/PhotoSorterCore.git`
4. Choose the version rule (recommended: "Up to Next Major Version" from 1.0.0)
5. Click **Add Package**
6. Select the target(s) where you want to use PhotoSorterCore
7. Click **Add Package** again

## Manual Installation

If you prefer to integrate PhotoSorterCore manually:

1. Clone the repository:
```bash
git clone https://github.com/yourusername/PhotoSorterCore.git
```

2. Drag the `PhotoSorterCore` folder into your Xcode project

3. Make sure to:
   - Add it to your target's dependencies
   - Set the minimum deployment target to macOS 15.0

## Verifying Installation

Create a simple test file to verify the installation:

```swift
import PhotoSorterCore

func testInstallation() {
    print("PhotoSorterCore is installed!")
    
    // Create a simple configuration to test
    let tempURL = FileManager.default.temporaryDirectory
    let config = SorterEngine.Configure(
        inputFolder: tempURL,
        outputFolder: tempURL,
        options: [],
        dateFormat: "YYYY-MM-DD"
    )
    
    print("Configuration created successfully: \(config)")
}

testInstallation()
```

If this compiles and runs without errors, PhotoSorterCore is correctly installed.

## Platform-Specific Notes

### macOS Sandboxing

If your app is sandboxed, you'll need to:

1. Enable the appropriate App Sandbox capabilities in your entitlements:
   - User Selected File (Read/Write)
   - File Access (Read/Write)

2. Use security-scoped bookmarks for persistent access:

```swift
// Save bookmark
func bookmark(url: URL) -> Data? {
    try? url.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
    )
}

// Restore from bookmark
func resolveBookmark(_ bookmarkData: Data) -> URL? {
    var isStale = false
    return try? URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
    )
}
```

### System Integrity Protection (SIP)

PhotoSorterCore uses system tools like `exiftool` and `xattr` for metadata manipulation. These are standard macOS utilities and don't require SIP to be disabled.

However, ensure these tools are available:

```swift
import Foundation

func checkSystemTools() {
    let tools = ["/usr/bin/xattr", "/usr/bin/mdls"]
    
    for tool in tools {
        let exists = FileManager.default.fileExists(atPath: tool)
        print("\(tool): \(exists ? "✅ Available" : "❌ Missing")")
    }
}
```

## Dependencies

PhotoSorterCore has **no external dependencies**. It uses only Apple's standard frameworks:

- Foundation
- CoreImage
- ImageIO
- UniformTypeIdentifiers
- AVFoundation

All frameworks are part of the standard macOS SDK.

## Updating

### Swift Package Manager

Update to the latest version:

```bash
swift package update PhotoSorterCore
```

Or in Xcode:
1. Go to **File → Packages → Update to Latest Package Versions**

### Checking Current Version

```swift
import PhotoSorterCore

// Version info is available in the package
print("PhotoSorterCore version: [Check Package.swift]")
```

## Uninstalling

### Swift Package Manager

1. In Xcode, go to your project settings
2. Select the **Package Dependencies** tab
3. Select PhotoSorterCore
4. Click the **-** button to remove

Or in `Package.swift`, remove the dependency and update:

```bash
swift package update
```

## Troubleshooting

### "No such module 'PhotoSorterCore'"

**Solution:**
1. Clean build folder: **Product → Clean Build Folder** (Shift+Cmd+K)
2. Close and reopen Xcode
3. Rebuild the project

### Package Resolution Failed

**Solution:**
1. Check your internet connection
2. Verify the repository URL is correct
3. Try resetting package caches:
```bash
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build
swift package reset
swift package resolve
```

### Minimum Deployment Target Error

**Solution:**
Ensure your project's minimum deployment target is macOS 15.0 or later:
1. Select your project in Xcode
2. Select your target
3. Go to **General** tab
4. Set **Minimum Deployments** to macOS 15.0

## Next Steps

Now that you have PhotoSorterCore installed:

- [Quick Start Guide](QuickStart.md) - Start using the library
- [Basic Concepts](BasicConcepts.md) - Understand core concepts
- [API Reference](api/) - Explore the API documentation

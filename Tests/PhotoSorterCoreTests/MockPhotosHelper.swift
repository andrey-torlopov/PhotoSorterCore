import Foundation
@testable import PhotoSorterCore

/// Mock implementation of PhotosHelping for testing
final class MockPhotosHelper: PhotosHelping {
    var generatedFilename: String = "test_file.jpg"
    var copyAttributesResult: Result<Bool, Error> = .success(true)

    var generateUniqueFilenameCalled = false
    var copyFileAttributesCalled = false

    func generateUniqueFilename(original: String, targetFolderURL: URL) -> String {
        generateUniqueFilenameCalled = true
        return generatedFilename
    }

    func copyFileAttributes(from sourceURL: URL, to destinationURL: URL) -> Result<Bool, Error> {
        copyFileAttributesCalled = true
        return copyAttributesResult
    }
}

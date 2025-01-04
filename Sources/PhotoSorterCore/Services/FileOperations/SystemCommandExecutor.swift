import Foundation

/// Protocol for executing system commands
public protocol SystemCommandExecuting {
    /// Executes a system command with given arguments
    /// - Parameters:
    ///   - executable: URL to the executable
    ///   - arguments: Array of command arguments
    /// - Returns: true if the command succeeded (exit code 0), false otherwise
    func execute(executable: URL, arguments: [String]) -> Bool
}

/// Default implementation using Process
public final class ProcessCommandExecutor: SystemCommandExecuting {

    public init() {}

    public func execute(executable: URL, arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

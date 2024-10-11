import Foundation

/// FileLock locks access to a file.
public class FileLock {

    /// options for file access type. See https://developer.apple.com/documentation/foundation/nsfilecoordinator
    /// for detailed behavior. In short : read doesn't prevent another read,
    /// but all the rest is blocking.
    public enum LockType {
        case read
        case write
        case delete
    }

    public enum FileLockError: Error {
        case lockingFailure(Error)
        case unexpectedError(String)
    }

    public func performInLock<T>(debugInfos: String, _ closure: () throws -> T) throws -> T {
        let fileCoordinator = NSFileCoordinator(filePresenter: nil)

        var res: T?
        var lockError: NSError?
        var closureThrownError: Error?

        logger(self, .debug, "try performInLock \(debugInfos) file \(filePath.path)")
        switch lockType {
        case .read:
            fileCoordinator.coordinate(
                readingItemAt: filePath,
                options: [],
                error: &lockError
            ) { _ in
                do { res = try closure() } catch { closureThrownError = error }
            }
        case .write:
            fileCoordinator.coordinate(
                writingItemAt: filePath,
                options: [],
                error: &lockError
            ) { _ in
                do { res = try closure() } catch { closureThrownError = error }
            }
        case .delete:
            fileCoordinator.coordinate(
                writingItemAt: filePath,
                options: .forDeleting,
                error: &lockError
            ) { _ in
                do { res = try closure() } catch { closureThrownError = error }
            }
        }

        // Coordinator returned an error : lock failed
        if let lockError {
            logger(self, .warning, "lock error trying performInLock \(debugInfos): \(lockError)")
            throw FileLockError.lockingFailure(lockError)
        }
        // The closure itself thrown an error, rethrow it
        if let closureThrownError {
            throw closureThrownError
        }
        // No result were found. This should never happen.
        guard let res else {
            logger(self, .error, "could not unwrap closure result \(debugInfos)")
            throw FileLockError.unexpectedError("could not unwrap closure result")
        }

        return res

    }

    let logger: Logger
    public let filePath: URL
    public let lockType: LockType
    public init(filePath: URL, lockType: LockType, logger: @escaping Logger) {
        self.filePath = filePath
        self.lockType = lockType
        self.logger = logger
    }
}

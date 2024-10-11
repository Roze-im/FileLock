import FileLockTesting
import XCTest

@testable import FileLock

final class FileLockTests: XCTestCase {

    func testResultClosureForwarded() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
        let filePath = root.appendingPathComponent("test.txt")
        let fileLock = FileLock(
            filePath: filePath,
            lockType: .write,
            logger: { print("[\($1)] \(Date()) \(String(describing: $0)) \($2)") }
        )

        // should not throw
        let res: Int = try fileLock.performInLock(debugInfos: "test") {
            return 3
        }
        XCTAssertEqual(res, 3)
    }

    func testNilResultClosure() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
        let filePath = root.appendingPathComponent("test.txt")
        let fileLock = FileLock(
            filePath: filePath,
            lockType: .write,
            logger: { print("[\($1)] \(Date()) \(String(describing: $0)) \($2)") }
        )

        // should not throw
        let res: Int? = try fileLock.performInLock(debugInfos: "test") {
            return nil
        }
        XCTAssertNil(res)
    }

    func testResultClosureRethrows() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
        let filePath = root.appendingPathComponent("test.txt")
        let fileLock = FileLock(
            filePath: filePath,
            lockType: .write,
            logger: { print("[\($1)] \(Date()) \(String(describing: $0)) \($2)") }
        )

        // should not throw
        do {
            _ = try fileLock.performInLock(debugInfos: "test") {
                throw NSError(domain: "hello", code: 2)
            }
            XCTFail("didn't rethrow")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "hello")
            XCTAssertEqual(error.code, 2)
        }
    }

    func testConcurrentThreadingLock() throws {
        let temporaryFile = FileManager.default.temporaryDirectory.appendingPathComponent("filelock.test.txt")
        let lock = FileLock(
            filePath: temporaryFile,
            lockType: .write,
            logger: { print("[\($1)] \(Date()) \(String(describing: $0)) \($2)") }
        )
        /* If you doubt that the test really validates anything, use the mock, it should make the test fail.
        let lock = MockFileLock { debugInfos in
            print(".")
        }
         */

        try Self.testCurrentThreadLocking(
            lock: lock,
            fileResource: lock.filePath,
            nbIncrement: 100,
            testCase: self
        )

        // now read the temporary file, making sure it contains '100'
        let data = try Data(contentsOf: lock.filePath)
        guard let dataString = String(data: data, encoding: .utf8),
            let dataInt = Int(dataString)
        else {
            throw NSError(domain: "could not decode string", code: 0)
        }
        XCTAssertEqual(dataInt, 100)
    }
}
extension FileLockTests {
    private static func readAndIncrement(
        contentOf file: URL,
        sleepBeforeWrite: TimeInterval = TimeInterval.random(in: 0.05..<0.1)
    ) throws {
        let data = try Data(contentsOf: file)
        guard let dataString = String(data: data, encoding: .utf8),
              let dataInt = Int(dataString) else {
            throw NSError(domain: "could not decode string", code: 0)
        }
        Thread.sleep(forTimeInterval: sleepBeforeWrite)
        try "\(dataInt + 1)".data(using: .utf8)?.write(to: file)
    }

    static func testCurrentThreadLocking(
        lock: FileLock,
        fileResource: URL? = nil,
        nbIncrement: Int = 100,
        testCase: XCTestCase
    ) throws {
        let fileResource = fileResource ?? FileManager.default.temporaryDirectory.appendingPathComponent("testfile")
        try "0".data(using: .utf8)?.write(to: fileResource)

        // simulator starts deadlocking at around 30 / 40 concurrent operations.
        let opQueue = OperationQueue(maxConcurrentOperationCount: 20)
        opQueue.underlyingQueue = DispatchQueue.global(qos: .userInitiated)
        let dispatchGroup = DispatchGroup()
        (0..<nbIncrement).forEach { i in
            dispatchGroup.enter()
            opQueue.addOperation {
                do {
                    try lock.performInLock(debugInfos: "\(i)") {
                        do {
                            try Self.readAndIncrement(contentOf: fileResource)
                        } catch {
                            XCTFail("readAndIncrementError : \(error)")
                        }
                    }
                } catch {
                    XCTFail("Unable to lock: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        dispatchGroup.wait()
        XCTAssertEqual("\(nbIncrement)", try? String(contentsOf: fileResource))
    }
}
extension OperationQueue {
    public convenience init(maxConcurrentOperationCount: Int, qualityOfService: QualityOfService = .default) {
        self.init()
        self.maxConcurrentOperationCount = maxConcurrentOperationCount
        self.qualityOfService = qualityOfService
    }
}


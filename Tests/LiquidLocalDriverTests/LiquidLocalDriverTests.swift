import XCTest
@testable import LiquidLocalDriver

final class LiquidLocalDriverTests: XCTestCase {
    
    private func createTestStorage() throws -> FileStorage {
        
        let baseUrl = #file.split(separator: "/").dropLast().joined(separator: "/")

        let elg = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let pool = NIOThreadPool(numberOfThreads: 1)
        pool.start()

        let fileio = NonBlockingFileIO(threadPool: pool)

        let storages = FileStorages(fileio: fileio)
        storages.use(.local(publicUrl: "http://localhost/", publicPath: baseUrl, workDirectory: "assets"), as: .local)
        return storages.fileStorage(.local, logger: .init(label: "[test-logger]"), on: elg.next())!
    }
    
    func testUpload() throws {
        let fs = try createTestStorage()
        let key = "test-01.txt"
        let data = Data("file storage test 01".utf8)
        let res = try fs.upload(key: key, data: data).wait()
        XCTAssertEqual(res, "http://localhost/assets/test-01.txt")
    }
    
    func testCreateDirectory() throws {
        let fs = try createTestStorage()
        let key = "dir01/dir02/dir03"
        let _ = try fs.createDirectory(key: key).wait()
        let keys1 = try fs.list(key: "dir01").wait()
        XCTAssertEqual(keys1, ["dir02"])
        let keys2 = try fs.list(key: "dir01/dir02").wait()
        XCTAssertEqual(keys2, ["dir03"])
    }
    
    func testList() throws {
        let fs = try createTestStorage()
        let key1 = "dir02/dir03"
        let _ = try fs.createDirectory(key: key1).wait()
        
        let key2 = "dir02/test-01.txt"
        let data = Data("test".utf8)
        _ = try fs.upload(key: key2, data: data).wait()
        
        let res = try fs.list(key: "dir02").wait()
        XCTAssertEqual(res, ["dir03", "test-01.txt"])
    }
    
}

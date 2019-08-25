import XCTest
@testable import swift_net

final class swift_netTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swift_net().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}

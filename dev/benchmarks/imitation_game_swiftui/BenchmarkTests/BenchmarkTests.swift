import XCTest

final class BenchmarkTests: XCTestCase {
    @MainActor
    func testTimeToFirstFrame() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

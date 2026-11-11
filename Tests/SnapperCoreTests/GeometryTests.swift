import XCTest
@testable import SnapperCore

final class GeometryTests: XCTestCase {
    private let left = CGRect(x: 0, y: 25, width: 1000, height: 800)
    private let right = CGRect(x: 1000, y: 0, width: 2000, height: 1200)

    func testDisplayIndexPicksTheLargestOverlap() {
        XCTAssertEqual(Geometry.displayIndex(for: CGRect(x: 800, y: 100, width: 400, height: 300), in: [left, right]), 0)
        XCTAssertEqual(Geometry.displayIndex(for: CGRect(x: 950, y: 100, width: 400, height: 300), in: [left, right]), 1)
    }

    func testDisplayIndexForOffscreenWindowIsTheNearest() {
        XCTAssertEqual(Geometry.displayIndex(for: CGRect(x: 5000, y: 0, width: 100, height: 100), in: [left, right]), 1)
        XCTAssertEqual(Geometry.displayIndex(for: CGRect(x: -900, y: 0, width: 100, height: 100), in: [left, right]), 0)
    }

    func testDefaultFrameIsCentredAndSixtyPercent() {
        let f = Geometry.defaultFrame(in: left)
        XCTAssertEqual(f.size, CGSize(width: 600, height: 480))
        XCTAssertEqual(f.midX, left.midX)
        XCTAssertEqual(f.midY, left.midY)
    }

    func testScaleKeepsRelativePlacementAndStaysInside() {
        let moved = Geometry.scale(CGRect(x: 500, y: 425, width: 500, height: 400), from: left, to: right)
        XCTAssertEqual(moved, CGRect(x: 2000, y: 600, width: 1000, height: 600))
        let huge = Geometry.scale(CGRect(x: 0, y: 25, width: 1000, height: 800), from: right, to: left)
        XCTAssertTrue(left.contains(huge))
    }

    func testIsCloseUsesToleranceOnEveryEdge() {
        let a = CGRect(x: 0, y: 0, width: 100, height: 100)
        XCTAssertTrue(a.isClose(to: CGRect(x: 3, y: -3, width: 103, height: 97), tolerance: 4))
        XCTAssertFalse(a.isClose(to: CGRect(x: 0, y: 0, width: 100, height: 110), tolerance: 4))
    }
}

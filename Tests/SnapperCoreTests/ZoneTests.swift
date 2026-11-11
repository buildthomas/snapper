import XCTest
@testable import SnapperCore

final class ZoneTests: XCTestCase {
    private let area = CGRect(x: 100, y: 25, width: 1001, height: 775) // odd sizes exercise the rounding

    func testQuartersTileTheArea() {
        let quarters = [Zone.topLeft, .topRight, .bottomLeft, .bottomRight].map { $0.rect(in: area)! }
        XCTAssertEqual(quarters.reduce(0) { $0 + $1.width * $1.height }, area.width * area.height)
        XCTAssertEqual(quarters.reduce(CGRect.null) { $0.union($1) }, area)
    }

    func testHalvesTileTheArea() {
        XCTAssertEqual(Zone.left.rect(in: area)!.union(Zone.right.rect(in: area)!), area)
        XCTAssertEqual(Zone.top.rect(in: area)!.union(Zone.bottom.rect(in: area)!), area)
        XCTAssertEqual(Zone.left.rect(in: area)!.maxX, Zone.right.rect(in: area)!.minX)
        XCTAssertEqual(Zone.top.rect(in: area)!.maxY, Zone.bottom.rect(in: area)!.minY)
    }

    func testMaximizedIsTheWholeArea() {
        XCTAssertEqual(Zone.maximized.rect(in: area), area)
        XCTAssertNil(Zone.other.rect(in: area))
    }

    func testMirroredSwapsSidesOnly() {
        XCTAssertEqual(Zone.left.mirrored, .right)
        XCTAssertEqual(Zone.topRight.mirrored, .topLeft)
        XCTAssertEqual(Zone.bottomLeft.mirrored, .bottomRight)
        for zone in [Zone.maximized, .top, .bottom, .other] { XCTAssertEqual(zone.mirrored, zone) }
        for zone in Zone.snapped { XCTAssertEqual(zone.mirrored.mirrored, zone) }
    }
}

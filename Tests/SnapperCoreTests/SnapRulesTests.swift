import XCTest
@testable import SnapperCore

final class SnapRulesTests: XCTestCase {
    private func act(_ d: Direction, _ zone: Zone, display: Int = 0, of count: Int = 1,
                     variant: Variant = .normal, minimizes: Bool = true) -> SnapAction {
        SnapRules.action(d, variant: variant, zone: zone, display: display, displayCount: count, downMinimizes: minimizes)
    }

    func testUpFromFreeWindowMaximizes() {
        XCTAssertEqual(act(.up, .other), .snap(.maximized, display: 0))
    }

    func testUpFromMaximizedGoesToTopHalfAndStaysThere() {
        XCTAssertEqual(act(.up, .maximized), .snap(.top, display: 0))
        XCTAssertEqual(act(.up, .top), .none)
    }

    func testDownFromMaximizedOrTopHalfRestores() {
        XCTAssertEqual(act(.down, .maximized), .restore)
        XCTAssertEqual(act(.down, .top), .restore)
    }

    func testDownFromBottomOrFreeMinimizesUnlessDisabled() {
        XCTAssertEqual(act(.down, .other), .minimize)
        XCTAssertEqual(act(.down, .bottom), .minimize)
        XCTAssertEqual(act(.down, .bottomLeft), .minimize)
        XCTAssertEqual(act(.down, .other, minimizes: false), .none)
    }

    func testQuarterSequences() {
        XCTAssertEqual(act(.up, .left), .snap(.topLeft, display: 0))
        XCTAssertEqual(act(.down, .left), .snap(.bottomLeft, display: 0))
        XCTAssertEqual(act(.down, .topLeft), .snap(.left, display: 0))
        XCTAssertEqual(act(.up, .bottomRight), .snap(.right, display: 0))
        XCTAssertEqual(act(.up, .topRight), .snap(.maximized, display: 0))
        XCTAssertEqual(act(.right, .topLeft), .snap(.topRight, display: 0))
        XCTAssertEqual(act(.left, .bottomRight), .snap(.bottomLeft, display: 0))
    }

    func testOppositeHalfRestores() {
        XCTAssertEqual(act(.left, .right), .restore)
        XCTAssertEqual(act(.right, .left), .restore)
    }

    func testFromFreeOrMaximizedSnapsToHalf() {
        XCTAssertEqual(act(.left, .other), .snap(.left, display: 0))
        XCTAssertEqual(act(.right, .maximized), .snap(.right, display: 0))
    }

    func testSingleDisplayStopsAtTheEdge() {
        XCTAssertEqual(act(.left, .left), .none)
        XCTAssertEqual(act(.right, .topRight), .none)
        XCTAssertEqual(act(.right, .right, variant: .display), .none)
    }

    func testRightWrapsAroundDisplays() {
        XCTAssertEqual(act(.right, .right, display: 0, of: 3), .snap(.left, display: 1))
        XCTAssertEqual(act(.right, .bottomRight, display: 2, of: 3), .snap(.bottomLeft, display: 0))
    }

    func testLeftWrapsAroundDisplays() {
        XCTAssertEqual(act(.left, .left, display: 1, of: 3), .snap(.right, display: 0))
        XCTAssertEqual(act(.left, .topLeft, display: 0, of: 2), .snap(.topRight, display: 1))
    }

    func testDisplayMoveKeepsTheZoneAndWraps() {
        XCTAssertEqual(act(.right, .topLeft, display: 0, of: 2, variant: .display), .snap(.topLeft, display: 1))
        XCTAssertEqual(act(.right, .left, display: 1, of: 2, variant: .display), .snap(.left, display: 0))
        XCTAssertEqual(act(.left, .maximized, display: 0, of: 2, variant: .display), .snap(.maximized, display: 1))
        XCTAssertEqual(act(.up, .left, display: 0, of: 2, variant: .display), .none)
    }

    func testHalfVariant() {
        XCTAssertEqual(act(.up, .other, display: 1, of: 2, variant: .half), .snap(.top, display: 1))
        XCTAssertEqual(act(.down, .maximized, variant: .half), .snap(.bottom, display: 0))
    }
}

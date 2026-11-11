import XCTest
@testable import SnapperCore

final class ShortcutModifierTests: XCTestCase {
    func testNormalMatchIgnoresArrowKeyFlags() {
        let held = ShortcutModifier.controlOption.flags.union([.maskSecondaryFn, .maskNumericPad])
        XCTAssertEqual(ShortcutModifier.controlOption.variant(for: .left, held: held), .normal)
    }

    func testExtraOrMissingModifierDoesNotMatch() {
        let m = ShortcutModifier.controlOption
        XCTAssertNil(m.variant(for: .left, held: .maskAlternate))
        XCTAssertNil(m.variant(for: .left, held: m.flags.union(.maskCommand)))
        XCTAssertNil(m.variant(for: .up, held: []))
    }

    func testShiftSelectsDisplayMoveOnHorizontalKeysOnly() {
        let m = ShortcutModifier.controlOption
        let shifted = m.flags.union(.maskShift)
        XCTAssertEqual(m.variant(for: .right, held: shifted), .display)
        XCTAssertNil(m.variant(for: .up, held: shifted))
    }

    func testHalfFlagsAddCommandOrShiftIfCommandIsTaken() {
        XCTAssertEqual(ShortcutModifier.controlOption.halfFlags, [.maskControl, .maskAlternate, .maskCommand])
        XCTAssertEqual(ShortcutModifier.controlCommand.halfFlags, [.maskControl, .maskCommand, .maskShift])
        XCTAssertEqual(ShortcutModifier.controlOption.variant(for: .up, held: ShortcutModifier.controlOption.halfFlags), .half)
        XCTAssertNil(ShortcutModifier.controlOption.variant(for: .left, held: ShortcutModifier.controlOption.halfFlags))
    }

    func testEveryPresetHasADistinctShortcut() {
        XCTAssertEqual(Set(ShortcutModifier.allCases.map { $0.flags.rawValue }).count, ShortcutModifier.allCases.count)
    }
}

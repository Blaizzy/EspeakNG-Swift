//
//  ESpeakNGTests.swift
//  ESpeakNGTests
//

import XCTest
@testable import ESpeakNGSwift

final class ESpeakNGTests: XCTestCase {
    func testLanguageDialectEnum() {
        XCTAssertEqual(ESpeakNGEngine.LanguageDialect.enUS.rawValue, "en-us")
        XCTAssertEqual(ESpeakNGEngine.LanguageDialect.enGB.rawValue, "en-gb")
    }
}
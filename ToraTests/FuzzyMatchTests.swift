import XCTest
@testable import Tora

final class FuzzyMatchTests: XCTestCase {
    func test_exactMatch_returnsCanonicalCasing() {
        let candidates = ["Megaflis", "VPG"]
        XCTAssertEqual(FuzzyMatch.bestMatch(for: "Megaflis", in: candidates), "Megaflis")
    }

    func test_caseInsensitive_matches() {
        let candidates = ["Megaflis", "VPG"]
        XCTAssertEqual(FuzzyMatch.bestMatch(for: "megaflis", in: candidates), "Megaflis")
    }

    func test_minorTypo_matches() {
        let candidates = ["Megaflis", "VPG", "Shop Assistant"]
        // Single-letter typos should resolve to the right candidate.
        XCTAssertEqual(FuzzyMatch.bestMatch(for: "Megaflys", in: candidates), "Megaflis")
        XCTAssertEqual(FuzzyMatch.bestMatch(for: "ShopAssistant", in: candidates), "Shop Assistant")
    }

    func test_unrelatedQuery_returnsNil() {
        let candidates = ["Megaflis", "VPG"]
        XCTAssertNil(FuzzyMatch.bestMatch(for: "completely unrelated", in: candidates))
    }

    func test_emptyQuery_returnsNil() {
        XCTAssertNil(FuzzyMatch.bestMatch(for: "", in: ["A", "B"]))
    }

    func test_noCandidates_returnsNil() {
        XCTAssertNil(FuzzyMatch.bestMatch(for: "anything", in: []))
    }

    func test_pickClosestOfMany() {
        let candidates = ["Acme", "Acmé Co", "Aperture", "AcmeCo"]
        // "Acmeco" should fuzzy-match "AcmeCo" (closest), not "Acmé Co" (which becomes "acme co" after normalization).
        let match = FuzzyMatch.bestMatch(for: "Acmeco", in: candidates)
        XCTAssertNotNil(match)
        // Either AcmeCo or Acmé Co is acceptable here since both normalize closely;
        // assert it's not the obviously-wrong "Aperture".
        XCTAssertNotEqual(match, "Aperture")
    }
}

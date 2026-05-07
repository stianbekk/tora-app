import Foundation

/// Lightweight fuzzy name matcher used to link AI-extracted customer/product
/// names against existing rows. Threshold is intentionally conservative —
/// when in doubt, we leave the link empty rather than mis-attribute.
enum FuzzyMatch {
    /// Default threshold. 1.0 = exact, 0.0 = nothing in common.
    static let defaultThreshold: Double = 0.86

    /// Returns the best matching candidate above `threshold`, or nil.
    static func bestMatch(
        for query: String,
        in candidates: [String],
        threshold: Double = defaultThreshold
    ) -> String? {
        let normalizedQuery = normalize(query)
        guard !normalizedQuery.isEmpty else { return nil }

        var bestScore: Double = 0
        var bestMatch: String?

        for candidate in candidates {
            let normalizedCandidate = normalize(candidate)
            if normalizedCandidate.isEmpty { continue }

            // Exact match short-circuits to 1.0 — handles case-insensitive/whitespace cases.
            if normalizedQuery == normalizedCandidate {
                return candidate
            }

            let score = jaroWinkler(normalizedQuery, normalizedCandidate)
            if score > bestScore {
                bestScore = score
                bestMatch = candidate
            }
        }

        return bestScore >= threshold ? bestMatch : nil
    }

    /// Normalizes for comparison: lowercase, strip punctuation, collapse whitespace.
    static func normalize(_ s: String) -> String {
        let lower = s.lowercased()
        let allowed = lower.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || $0 == " " }
        return String(String.UnicodeScalarView(allowed))
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    /// Jaro-Winkler similarity. Returns a score in [0, 1] where 1 means identical.
    /// Implementation follows the standard formula: Jaro distance with prefix
    /// boost up to 4 characters.
    static func jaroWinkler(_ a: String, _ b: String) -> Double {
        let jaroScore = jaro(a, b)
        guard jaroScore > 0.7 else { return jaroScore }

        let prefixLen = commonPrefix(a, b, max: 4)
        let scaling = 0.1
        return jaroScore + Double(prefixLen) * scaling * (1 - jaroScore)
    }

    static func jaro(_ a: String, _ b: String) -> Double {
        let aChars = Array(a)
        let bChars = Array(b)
        if aChars.isEmpty && bChars.isEmpty { return 1.0 }
        if aChars.isEmpty || bChars.isEmpty { return 0.0 }

        let matchDistance = max(0, max(aChars.count, bChars.count) / 2 - 1)
        var aMatches = Array(repeating: false, count: aChars.count)
        var bMatches = Array(repeating: false, count: bChars.count)

        var matches = 0
        for i in 0..<aChars.count {
            let start = max(0, i - matchDistance)
            let end = min(i + matchDistance + 1, bChars.count)
            guard start < end else { continue }
            for j in start..<end where !bMatches[j] && aChars[i] == bChars[j] {
                aMatches[i] = true
                bMatches[j] = true
                matches += 1
                break
            }
        }
        if matches == 0 { return 0.0 }

        var transpositions = 0
        var k = 0
        for i in 0..<aChars.count where aMatches[i] {
            while !bMatches[k] { k += 1 }
            if aChars[i] != bChars[k] { transpositions += 1 }
            k += 1
        }
        let m = Double(matches)
        return (m / Double(aChars.count)
              + m / Double(bChars.count)
              + (m - Double(transpositions) / 2) / m) / 3
    }

    private static func commonPrefix(_ a: String, _ b: String, max maxLen: Int) -> Int {
        var count = 0
        for (c1, c2) in zip(a, b) {
            if c1 != c2 || count >= maxLen { break }
            count += 1
        }
        return count
    }
}

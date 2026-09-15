import Foundation

/// Pure URL operations: do not read or download the selected files.
enum PathFormatter {
    static func relativePath(of target: URL, to base: URL) -> String {
        let baseParts = base.standardizedFileURL.pathComponents
        let targetParts = target.standardizedFileURL.pathComponents
        var common = 0
        while common < min(baseParts.count, targetParts.count),
              baseParts[common] == targetParts[common] {
            common += 1
        }
        let parts = Array(repeating: "..", count: baseParts.count - common)
            + targetParts.dropFirst(common)
        return parts.isEmpty ? "." : parts.joined(separator: "/")
    }
}

import Foundation

enum ProjectPaths {
    static func loadRoots() -> [String] {
        guard let file = SharedStore.sharedDirectoryURL?.appendingPathComponent("project_roots.json"),
              let data = try? Data(contentsOf: file),
              let roots = try? JSONDecoder().decode([String].self, from: data) else { return [] }
        return roots
    }

    static func saveRoots(_ roots: [String]) throws {
        guard let directory = SharedStore.sharedDirectoryURL else {
            throw CocoaError(.fileNoSuchFile)
        }
        try JSONEncoder().encode(roots).write(
            to: directory.appendingPathComponent("project_roots.json"), options: .atomic)
    }

    /// Configured roots take priority; nested roots use the longest component match.
    /// Git detection checks marker existence only, including worktree .git files.
    static func path(for target: URL, roots: [String],
                     markerExists: (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }) -> String {
        let target = target.standardizedFileURL
        let components = target.pathComponents
        let matches = roots.filter { $0.hasPrefix("/") }.map {
            URL(fileURLWithPath: $0).standardizedFileURL
        }.filter { components.starts(with: $0.pathComponents) }
        if let root = matches.max(by: { $0.pathComponents.count < $1.pathComponents.count }) {
            return PathFormatter.relativePath(of: target, to: root)
        }
        var directory = target
        while true {
            if markerExists(directory.appendingPathComponent(".git")) {
                return PathFormatter.relativePath(of: target, to: directory)
            }
            guard directory.pathComponents.count > 1 else { break }
            directory = URL(fileURLWithPath: (directory.path as NSString).deletingLastPathComponent,
                            isDirectory: true).standardizedFileURL
        }
        // Do not guess a project boundary from Documents or the username.
        return target.path
    }

    static func text(for urls: [URL], roots: [String]) -> String {
        urls.map { path(for: $0, roots: roots) }.joined(separator: "\n")
    }
}

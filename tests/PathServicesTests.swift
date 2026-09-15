import AppKit

@main
struct PathServicesTests {
    @MainActor static func main() {
        func url(_ path: String) -> URL { URL(fileURLWithPath: path) }
        for (base, target, expected) in [
            ("/a/b", "/a/b/file.txt", "file.txt"),
            ("/a/b", "/a/c/file.txt", "../c/file.txt"),
            ("/a/b", "/a/b", "."),
            ("/", "/a/file.txt", "a/file.txt"),
            ("/a/b", "/a", ".."),
            ("/a/b", "/a/bc/file", "../bc/file"),
            ("/a/b", "/a/b/sub/../中文 #%.txt", "中文 #%.txt")
        ] {
            precondition(PathFormatter.relativePath(of: url(target), to: url(base)) == expected)
        }
        let noGit: (URL) -> Bool = { _ in false }
        precondition(ProjectPaths.path(for: url("/work/TCM/outputs/a.txt"), roots: ["/work/TCM"], markerExists: noGit) == "outputs/a.txt")
        precondition(ProjectPaths.path(for: url("/work/TCM/sub/a.txt"), roots: ["/work/TCM", "/work/TCM/sub"], markerExists: noGit) == "a.txt")
        precondition(ProjectPaths.path(for: url("/work/TCM2/a.txt"), roots: ["/work/TCM"], markerExists: noGit) == "/work/TCM2/a.txt")
        precondition(ProjectPaths.path(for: url("/work/TCM"), roots: ["/work/TCM"], markerExists: noGit) == ".")
        precondition(ProjectPaths.path(for: url("/work/TCM/a.txt"), roots: [], markerExists: { $0.path == "/work/TCM/.git" }) == "a.txt")
        precondition(ProjectPaths.path(for: url("/work/TCM/sub/a.txt"), roots: ["/work/TCM"], markerExists: { $0.path == "/work/TCM/sub/.git" }) == "sub/a.txt")
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: temp.appendingPathComponent("repo"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        // A worktree uses a file for .git; a regular repo uses a directory.
        let marker = temp.appendingPathComponent("repo/.git")
        try! Data("gitdir: /unused".utf8).write(to: marker)
        let child = temp.appendingPathComponent("repo/sub/missing.txt")
        precondition(ProjectPaths.path(for: child, roots: []) == "sub/missing.txt")
        try! FileManager.default.removeItem(at: marker)
        try! FileManager.default.createDirectory(at: marker, withIntermediateDirectories: true)
        precondition(ProjectPaths.path(for: child, roots: []) == "sub/missing.txt")
        let input = NSPasteboard.withUniqueName()
        let output = NSPasteboard.withUniqueName()
        defer { input.releaseGlobally(); output.releaseGlobally() }
        // Deliberately nonexistent cloud paths: copying must not require content.
        let base = url("/Users/test/Library/Mobile Documents/com~apple~CloudDocs/Documents")
        let urls = [base.appendingPathComponent("中文 #%.txt"), base.appendingPathComponent("folder/other.txt")]
        precondition(input.writeObjects(urls as [NSURL]))
        var rootCalls = 0
        let provider = PathServices(output: output) { rootCalls += 1; return [base.path] }
        var error: NSString?
        provider.copyPath(input, userData: "absolute", error: &error)
        precondition(error == nil && output.string(forType: .string) == urls.map(\.path).joined(separator: "\n"))
        provider.copyPath(input, userData: "name", error: &error)
        precondition(error == nil && output.string(forType: .string) == "中文 #%.txt\nother.txt")
        precondition(rootCalls == 0)
        provider.copyPath(input, userData: "relative", error: &error)
        precondition(error == nil && output.string(forType: .string) == "中文 #%.txt\nfolder/other.txt")
        precondition(rootCalls == 1)
        let fallback = PathServices(output: output, projectRoots: { [] })
        fallback.copyPath(input, userData: "relative", error: &error)
        let expected = urls.map(\.path).joined(separator: "\n")
        precondition(error == nil && output.string(forType: .string) == expected)
        input.clearContents()
        provider.copyPath(input, userData: "absolute", error: &error)
        precondition(error != nil && output.string(forType: .string) == expected)
        error = nil
        provider.copyPath(input, userData: "invalid", error: &error)
        precondition(error != nil && output.string(forType: .string) == expected)
        precondition(provider.responds(to: NSSelectorFromString("copyPath:userData:error:")))
        print("PASS: relative paths, cloud URLs, multi-selection, Unicode, fallback, invalid input and service selector")
    }
}

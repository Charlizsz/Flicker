import AppKit

@MainActor
final class PathServices: NSObject {
    enum Format: String { case absolute, relative, name }

    private let output: NSPasteboard
    private let projectRoots: @MainActor () -> [String]

    init(output: NSPasteboard = .general,
         projectRoots: @escaping @MainActor () -> [String] = { ProjectPaths.loadRoots() }) {
        self.output = output
        self.projectRoots = projectRoots
        super.init()
    }

    func copyProjectURLs(_ urls: [URL]) {
        guard !urls.isEmpty, urls.allSatisfy(\.isFileURL) else { return }
        let text = ProjectPaths.text(for: urls, roots: projectRoots())
        output.clearContents()
        output.setString(text, forType: .string)
    }

    @objc func copyPath(_ pasteboard: NSPasteboard, userData: String?,
                        error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let userData, let format = Format(rawValue: userData) else {
            error.pointee = "无法识别复制路径操作。"
            return
        }
        let urls = (pasteboard.readObjects(forClasses: [NSURL.self],
                    options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? [])
            .filter(\.isFileURL)
        guard !urls.isEmpty else {
            error.pointee = "请选择文件或文件夹后重试。"
            return
        }
        let roots = format == .relative ? projectRoots() : []
        let text = urls.map { url in
            switch format {
            case .absolute: return url.path
            case .name: return url.lastPathComponent
            case .relative:
                return ProjectPaths.path(for: url, roots: roots)
            }
        }.joined(separator: "\n")
        output.clearContents()
        if !output.setString(text, forType: .string) {
            error.pointee = "无法将路径写入剪贴板，请重试。"
        }
    }

}

import SwiftUI
import AppKit

struct ProjectDirectoriesPanel: View {
    @State private var roots: [String] = []
    @State private var selection = Set<String>()
    @State private var query = ""
    @State private var saveError: String?

    private var filteredRoots: [String] {
        roots.filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("项目目录").font(.title2).bold()
            Text("「复制项目内路径」会去掉项目根目录，例如复制为 outputs/result.txt。Git 项目无需添加，会自动识别；其他项目在这里选择根文件夹即可。")
                .foregroundStyle(.secondary)
            TextField("搜索项目名称或路径", text: $query)
                .textFieldStyle(.roundedBorder)
            List(selection: $selection) {
                ForEach(filteredRoots, id: \.self) { path in
                    VStack(alignment: .leading, spacing: 4) {
                        Label(URL(fileURLWithPath: path).lastPathComponent, systemImage: "folder")
                        Text(path).font(.caption).foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 3)
                    .tag(path)
                }
            }
            HStack {
                Button("添加项目文件夹…", action: addDirectories)
                Button("移除所选") {
                    if persist(roots.filter { !selection.contains($0) }) { selection.removeAll() }
                }
                .disabled(selection.isEmpty)
                Spacer()
                Text("\(roots.count) 个项目").foregroundStyle(.secondary)
            }
            Text("优先使用列表中匹配最深的项目目录，其次查找最近的 Git 根目录；找不到时复制绝对路径。移除项目只删除此处的设置，不会删除文件。")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24)
        .onAppear { roots = ProjectPaths.loadRoots() }
        .alert("无法保存项目目录", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) {
            Button("好", role: .cancel) { saveError = nil }
        } message: { Text(saveError ?? "") }
    }

    private func addDirectories() {
        let panel = NSOpenPanel()
        panel.title = "选择项目根文件夹"
        panel.prompt = "添加项目"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        let additions = panel.urls.map { $0.standardizedFileURL.path }
        _ = persist(Array(Set(roots + additions)).sorted())
    }

    @discardableResult private func persist(_ updated: [String]) -> Bool {
        do {
            try ProjectPaths.saveRoots(updated)
            roots = updated
            return true
        } catch {
            saveError = error.localizedDescription
            return false
        }
    }
}

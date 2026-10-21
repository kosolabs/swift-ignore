// Adapted from https://github.com/BurntSushi/ripgrep/blob/020687a77d13146923333f0beb274eeabd54a270/crates/ignore/src/dir.rs

struct IgnoreStack: Sendable {
  private let filenames: [String]
  private let global: IgnoreRules
  private let directory: String
  private let levels: [[IgnoreRules?]]

  init(filenames: [String], global: String = "", files: [String: String] = [:]) {
    self.filenames = filenames
    self.global = Self.rules(global: global)
    self.directory = ""
    self.levels = [Self.rules(for: filenames, in: "", files: files)]
  }

  private init(parent: IgnoreStack, directory: String, files: [String: String]) {
    self.filenames = parent.filenames
    self.global = parent.global
    self.directory = directory
    self.levels = parent.levels + [Self.rules(for: parent.filenames, in: directory, files: files)]
  }

  func child(_ name: String, files: [String: String]) -> IgnoreStack {
    IgnoreStack(
      parent: self,
      directory: directory.isEmpty ? name : "\(directory)/\(name)",
      files: files
    )
  }

  func matched(_ name: String, isDirectory: Bool) -> Match {
    let path = directory.isEmpty ? name : "\(directory)/\(name)"
    return Self.matched(path, isDirectory: isDirectory, levels: levels, global: global)
  }

  static func matched(
    _ path: String,
    isDirectory: Bool,
    levels: [[IgnoreRules?]],
    global: IgnoreRules
  ) -> Match {
    for i in (levels.first ?? []).indices.reversed() {
      for level in levels.reversed() {
        guard let rules = level[i] else { continue }
        let match = rules.matched(path, isDirectory: isDirectory)
        if !match.isUnmatched { return match }
      }
    }
    return global.matched(path, isDirectory: isDirectory)
  }

  static func rules(global: String) -> IgnoreRules {
    var builder = IgnoreRulesBuilder(root: "")
    builder.addStr(file: nil, global)
    return builder.build()
  }

  static func rules(
    for filenames: [String],
    in directory: String,
    files: [String: String]
  ) -> [IgnoreRules?] {
    filenames.map { name in
      files[name].map { contents in
        var builder = IgnoreRulesBuilder(root: directory)
        builder.addStr(file: directory.isEmpty ? name : "\(directory)/\(name)", contents)
        return builder.build()
      }
    }
  }
}

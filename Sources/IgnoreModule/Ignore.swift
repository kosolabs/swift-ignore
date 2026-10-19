// Adapted from https://github.com/BurntSushi/ripgrep/blob/020687a77d13146923333f0beb274eeabd54a270/crates/ignore/src/dir.rs

public struct Ignore: Sendable {
  private let filenames: [String]
  private let global: IgnoreRules
  private let directory: String
  private let levels: [[IgnoreRules?]]

  public init(filenames: [String], global: String = "", files: [String: String] = [:]) {
    var builder = IgnoreRulesBuilder(root: "")
    builder.addStr(from: nil, global)
    self.filenames = filenames
    self.global = builder.build()
    self.directory = ""
    self.levels = [Self.rules(for: filenames, in: "", files: files)]
  }

  private init(parent: Ignore, directory: String, files: [String: String]) {
    self.filenames = parent.filenames
    self.global = parent.global
    self.directory = directory
    self.levels = parent.levels + [Self.rules(for: parent.filenames, in: directory, files: files)]
  }

  public func child(_ name: String, files: [String: String]) -> Ignore {
    Ignore(parent: self, directory: directory.isEmpty ? name : "\(directory)/\(name)", files: files)
  }

  public func matched(_ name: String, isDir: Bool) -> Match<Glob> {
    let path = directory.isEmpty ? name : "\(directory)/\(name)"
    for i in filenames.indices.reversed() {
      for level in levels.reversed() {
        guard let rules = level[i] else { continue }
        let match = rules.matched(path, isDir: isDir)
        if !match.isNone { return match }
      }
    }
    return global.matched(path, isDir: isDir)
  }

  private static func rules(
    for filenames: [String],
    in directory: String,
    files: [String: String]
  ) -> [IgnoreRules?] {
    filenames.map { name in
      files[name].map { contents in
        var builder = IgnoreRulesBuilder(root: directory)
        builder.addStr(from: directory.isEmpty ? name : "\(directory)/\(name)", contents)
        return builder.build()
      }
    }
  }
}

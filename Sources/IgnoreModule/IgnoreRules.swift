// Ported from https://github.com/BurntSushi/ripgrep/blob/020687a77d13146923333f0beb274eeabd54a270/crates/ignore/src/gitignore.rs

public struct Glob: Sendable, Hashable {
  public let from: String?
  public let original: String
  public let actual: String
  public let isWhitelist: Bool
  public let isOnlyDir: Bool
}

public struct IgnoreRules: Sendable {
  private let root: String
  private let globs: [(glob: Glob, pattern: GlobPattern)]

  fileprivate init(root: String, globs: [(glob: Glob, pattern: GlobPattern)]) {
    self.root = root
    self.globs = globs
  }

  public func matched(_ path: String, isDir: Bool) -> Match<Glob> {
    let path = String(strip(path))
    for (glob, pattern) in globs.reversed() where !glob.isOnlyDir || isDir {
      if pattern.matches(path) {
        return glob.isWhitelist ? .whitelist(glob) : .ignore(glob)
      }
    }
    return .none
  }

  private func strip(_ path: String) -> Substring {
    var path = Substring(path)
    if path.hasPrefix("./") {
      path = path.dropFirst(2)
    }
    guard !root.isEmpty, root != ".", path.contains("/") else { return path }
    let prefix = root.hasSuffix("/") ? root : root + "/"
    if path.hasPrefix(prefix) {
      path = path.dropFirst(prefix.count)
    }
    return path
  }
}

public struct IgnoreRulesBuilder: Sendable {
  public var caseInsensitive = false

  private let root: String
  private var globs: [(glob: Glob, pattern: GlobPattern)] = []

  public init(root: String) {
    self.root = root.hasPrefix("./") ? String(root.dropFirst(2)) : root
  }

  public mutating func addLine(from: String?, _ line: String) {
    if line.hasPrefix("#") { return }
    var line = Self.trimTrailingWhitespace(Substring(line))
    if line.isEmpty { return }
    let original = String(line)
    var isWhitelist = false
    var isAbsolute = false
    var isOnlyDir = false
    if line.hasPrefix("\\!") || line.hasPrefix("\\#") {
      line = line.dropFirst()
    } else {
      if line.hasPrefix("!") {
        isWhitelist = true
        line = line.dropFirst()
      }
      if line.hasPrefix("/") {
        isAbsolute = true
        line = line.dropFirst()
      }
    }
    if line.hasSuffix("/") {
      isOnlyDir = true
      line = line.dropLast()
    }
    var actual = String(line)
    if !isAbsolute && !line.contains("/") && !actual.hasPrefix("**/") && actual != "**" {
      actual = "**/" + actual
    }
    let glob = Glob(
      from: from,
      original: original,
      actual: actual,
      isWhitelist: isWhitelist,
      isOnlyDir: isOnlyDir
    )
    globs.append((glob, GlobPattern(actual, caseInsensitive: caseInsensitive)))
  }

  mutating func addStr(from: String?, _ gitignore: String) {
    let contents = gitignore.hasPrefix("\u{FEFF}") ? gitignore.dropFirst() : Substring(gitignore)
    for line in contents.split(whereSeparator: \.isNewline) {
      addLine(from: from, String(line))
    }
  }

  public func build() -> IgnoreRules {
    IgnoreRules(root: root, globs: globs)
  }

  private static func trimTrailingWhitespace(_ line: Substring) -> Substring {
    var end = line.endIndex
    while end > line.startIndex {
      let last = line.index(before: end)
      guard line[last] == " " || line[last] == "\t" else { break }
      if last > line.startIndex && line[line.index(before: last)] == "\\" { break }
      end = last
    }
    return line[..<end]
  }
}

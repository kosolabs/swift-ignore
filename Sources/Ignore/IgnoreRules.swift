// Ported from https://github.com/BurntSushi/ripgrep/blob/020687a77d13146923333f0beb274eeabd54a270/crates/ignore/src/gitignore.rs

public struct Rule: Sendable, Hashable {
  public let file: String?
  public let original: String
  public let pattern: String
  public let isNegated: Bool
  public let isDirectoryOnly: Bool
}

struct IgnoreRules: Sendable {
  private let root: String
  private let rules: [(rule: Rule, glob: GlobPattern)]

  fileprivate init(root: String, rules: [(rule: Rule, glob: GlobPattern)]) {
    self.root = root
    self.rules = rules
  }

  func matched(_ path: String, isDirectory: Bool) -> Match {
    let path = String(strip(path))
    for (rule, glob) in rules.reversed() where !rule.isDirectoryOnly || isDirectory {
      if glob.matches(path) {
        return rule.isNegated ? .included(rule) : .ignored(rule)
      }
    }
    return .unmatched
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

struct IgnoreRulesBuilder: Sendable {
  var caseInsensitive = false

  private let root: String
  private var rules: [(rule: Rule, glob: GlobPattern)] = []

  init(root: String) {
    self.root = root.hasPrefix("./") ? String(root.dropFirst(2)) : root
  }

  mutating func addLine(file: String?, _ line: String) {
    if line.hasPrefix("#") { return }
    var line = Self.trimTrailingWhitespace(Substring(line))
    if line.isEmpty { return }
    let original = String(line)
    var isNegated = false
    var isAbsolute = false
    var isDirectoryOnly = false
    if line.hasPrefix("\\!") || line.hasPrefix("\\#") {
      line = line.dropFirst()
    } else {
      if line.hasPrefix("!") {
        isNegated = true
        line = line.dropFirst()
      }
      if line.hasPrefix("/") {
        isAbsolute = true
        line = line.dropFirst()
      }
    }
    if line.hasSuffix("/") {
      isDirectoryOnly = true
      line = line.dropLast()
    }
    var pattern = String(line)
    if !isAbsolute && !line.contains("/") && !pattern.hasPrefix("**/") && pattern != "**" {
      pattern = "**/" + pattern
    }
    let rule = Rule(
      file: file,
      original: original,
      pattern: pattern,
      isNegated: isNegated,
      isDirectoryOnly: isDirectoryOnly
    )
    rules.append((rule, GlobPattern(pattern, caseInsensitive: caseInsensitive)))
  }

  mutating func addStr(file: String?, _ gitignore: String) {
    let contents = gitignore.hasPrefix("\u{FEFF}") ? gitignore.dropFirst() : Substring(gitignore)
    for line in contents.split(whereSeparator: \.isNewline) {
      addLine(file: file, String(line))
    }
  }

  func build() -> IgnoreRules {
    IgnoreRules(root: root, rules: rules)
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

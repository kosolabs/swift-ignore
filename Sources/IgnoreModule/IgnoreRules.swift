public struct Glob: Sendable, Hashable {
  public let from: String?
  public let original: String
  public let actual: String
  public let isWhitelist: Bool
  public let isOnlyDir: Bool
}

public struct IgnoreRules: Sendable {
  public func matched(_ path: String, isDir: Bool) -> Match<Glob> {
    .none
  }
}

public struct IgnoreRulesBuilder: Sendable {
  public var caseInsensitive = false

  private let root: String

  public init(root: String) {
    self.root = root
  }

  public mutating func addLine(from: String?, _ line: String) {
  }

  mutating func addStr(from: String?, _ gitignore: String) {
    for line in gitignore.split(whereSeparator: \.isNewline) {
      addLine(from: from, String(line))
    }
  }

  public func build() -> IgnoreRules {
    IgnoreRules()
  }
}

func parseExcludesFile(_ data: String) -> String? {
  ""
}

func expandTilde(_ path: String) -> String {
  path
}

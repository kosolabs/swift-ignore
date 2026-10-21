public enum Match: Sendable, Equatable {
  case unmatched
  case ignored(Rule)
  case included(Rule)

  public var isUnmatched: Bool {
    if case .unmatched = self { true } else { false }
  }

  public var isIgnored: Bool {
    if case .ignored = self { true } else { false }
  }

  public var isIncluded: Bool {
    if case .included = self { true } else { false }
  }
}

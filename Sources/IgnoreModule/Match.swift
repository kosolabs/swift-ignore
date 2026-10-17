public enum Match<T> {
  case none
  case ignore(T)
  case whitelist(T)

  public var isNone: Bool {
    if case .none = self { true } else { false }
  }

  public var isIgnore: Bool {
    if case .ignore = self { true } else { false }
  }

  public var isWhitelist: Bool {
    if case .whitelist = self { true } else { false }
  }
}

extension Match: Sendable where T: Sendable {}
extension Match: Equatable where T: Equatable {}

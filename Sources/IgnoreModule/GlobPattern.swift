struct GlobPattern: Sendable {
  init(_ pattern: String, caseInsensitive: Bool = false) {
  }

  func matches(_ path: String) -> Bool {
    false
  }
}

public struct Ignore: Sendable {
  public init(filenames: [String], global: String = "", files: [String: String] = [:]) {
  }

  public func child(_ name: String, files: [String: String]) -> Ignore {
    self
  }

  public func matched(_ path: String, isDir: Bool) -> Match<Glob> {
    .none
  }
}

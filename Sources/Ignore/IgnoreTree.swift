public struct IgnoreTree: Sendable {
  private let filenames: [String]
  private let global: IgnoreRules
  private var directories: [String: Directory] = [:]

  private struct Directory: Sendable {
    let files: [String: String]
    let rules: [IgnoreRules?]
  }

  public init(filenames: [String], global: String = "") {
    self.filenames = filenames
    self.global = IgnoreStack.rules(global: global)
  }

  public func knows(_ dir: String) -> Bool {
    directories[Self.normalized(dir)] != nil
  }

  /// The ignore files recorded in `dir`, or nil if it's unknown.
  public func files(in dir: String) -> [String: String]? {
    directories[Self.normalized(dir)]?.files
  }

  /// Records the ignore files in `dir` and returns whether they changed. An unknown
  /// directory counts as having none.
  @discardableResult
  public mutating func set(_ files: [String: String], in dir: String) -> Bool {
    let dir = Self.normalized(dir)
    let files = files.filter { filenames.contains($0.key) }
    let known = directories[dir]
    if known?.files == files { return false }
    directories[dir] = Directory(
      files: files,
      rules: IgnoreStack.rules(for: filenames, in: dir, files: files)
    )
    return files != known?.files ?? [:]
  }

  @discardableResult
  public mutating func remove(_ filename: String, in dir: String) -> Bool {
    let dir = Self.normalized(dir)
    guard var files = directories[dir]?.files, files.removeValue(forKey: filename) != nil
    else { return false }
    set(files, in: dir)
    return true
  }

  /// Matches `path`, or the first of its parent directories that's ignored. Returns nil
  /// when a directory on the way is unknown.
  public func matched(_ path: String, isDirectory: Bool) -> Match? {
    let names = path.split(separator: "/").map(String.init)
    var dir = ""
    var levels: [[IgnoreRules?]] = []
    for (i, name) in names.enumerated() {
      guard let directory = directories[dir] else { return nil }
      levels.append(directory.rules)
      let path = dir.isEmpty ? name : "\(dir)/\(name)"
      let isLast = i == names.count - 1
      let match = IgnoreStack.matched(
        path,
        isDirectory: isLast ? isDirectory : true,
        levels: levels,
        global: global
      )
      if isLast || match.isIgnored { return match }
      dir = path
    }
    return knows("") ? Match.unmatched : nil
  }

  private static func normalized(_ dir: String) -> String {
    dir.split(separator: "/").joined(separator: "/")
  }
}

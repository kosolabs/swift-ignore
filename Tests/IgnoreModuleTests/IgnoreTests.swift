// Adapted from the dir.rs and walk.rs tests at
// https://github.com/BurntSushi/ripgrep/tree/020687a77d13146923333f0beb274eeabd54a270/crates/ignore/src

import Testing

@testable import IgnoreModule

struct IgnoreTests {
  @Test func explicitIgnore() {
    pending("explicitIgnore") {
      let ignore = Ignore(filenames: [], global: "foo\n!bar")
      #expect(ignore.matched("foo", isDir: false).isIgnore)
      #expect(ignore.matched("bar", isDir: false).isWhitelist)
      #expect(ignore.matched("baz", isDir: false).isNone)
    }
  }

  @Test func customIgnore() {
    pending("customIgnore") {
      let ignore = Ignore(filenames: [".customignore"], files: [".customignore": "foo\n!bar"])
      #expect(ignore.matched("foo", isDir: false).isIgnore)
      #expect(ignore.matched("bar", isDir: false).isWhitelist)
      #expect(ignore.matched("baz", isDir: false).isNone)
    }
  }

  // Later filenames take precedence over earlier ones.
  @Test func customIgnorePrecedence() {
    pending("customIgnorePrecedence") {
      let ignore = Ignore(
        filenames: [".customignore1", ".customignore2"],
        files: [".customignore1": "foo", ".customignore2": "!foo"]
      )
      #expect(ignore.matched("foo", isDir: false).isWhitelist)
    }
  }

  // Adapted from exclude_lowest: global rules take the place of
  // .git/info/exclude as the lowest precedence.
  @Test func globalLowest() {
    pending("globalLowest") {
      let ignore = Ignore(
        filenames: [".gitignore", ".customignore"],
        global: "foo\nbar\nbaz",
        files: [".gitignore": "!foo", ".customignore": "!bar"]
      )
      #expect(ignore.matched("baz", isDir: false).isIgnore)
      #expect(ignore.matched("foo", isDir: false).isWhitelist)
      #expect(ignore.matched("bar", isDir: false).isWhitelist)
    }
  }

  @Test func notPresent() {
    pending("notPresent") {
      let ignore = Ignore(filenames: [".gitignore"])
      #expect(ignore.matched("foo", isDir: false).isNone)
    }
  }

  // Adapted from stops_at_git_dir, without the .git barrier.
  @Test func parentRulesApplyInChild() {
    pending("parentRulesApplyInChild") {
      let root = Ignore(filenames: [".gitignore"], files: [".gitignore": "bar"])
      let foo = root.child("foo", files: [:])
      #expect(root.matched("bar", isDir: false).isIgnore)
      #expect(foo.matched("foo/bar", isDir: false).isIgnore)
    }
  }

  // Adapted from absolute_parent_anchored.
  @Test func anchoredToOwnDirectory() {
    pending("anchoredToOwnDirectory") {
      let root = Ignore(filenames: [".gitignore"], files: [".gitignore": "/llvm/\nfoo"])
      let src = root.child("src", files: [:])
      #expect(root.matched("llvm", isDir: true).isIgnore)
      #expect(src.matched("src/llvm", isDir: true).isNone)
      #expect(src.matched("src/foo", isDir: false).isIgnore)
    }
  }

  // Not from upstream.
  @Test func nearestDirectoryWins() {
    pending("nearestDirectoryWins") {
      let root = Ignore(filenames: [".gitignore"], files: [".gitignore": "*.log"])
      let src = root.child("src", files: [".gitignore": "!keep.log"])
      #expect(src.matched("src/keep.log", isDir: false).isWhitelist)
      #expect(src.matched("src/other.log", isDir: false).isIgnore)
    }
  }

  @Test func walkNoIgnores() {
    pending("walkNoIgnores") {
      let tree = ["a/b/c/": "", "x/y/": "", "a/b/foo": "", "x/y/foo": ""]
      #expect(
        walk(tree, filenames: [])
          == ["a", "a/b", "a/b/c", "a/b/foo", "x", "x/y", "x/y/foo"]
      )
    }
  }

  @Test func walkCustomIgnore() {
    pending("walkCustomIgnore") {
      let tree = [".customignore": "foo", "foo": "", "a/foo": "", "bar": "", "a/bar": ""]
      #expect(
        walk(tree, filenames: [".customignore"]) == [".customignore", "a", "a/bar", "bar"]
      )
    }
  }

  @Test func walkExplicitIgnore() {
    pending("walkExplicitIgnore") {
      let tree = ["foo": "", "a/foo": "", "bar": "", "a/bar": ""]
      #expect(walk(tree, filenames: [], global: "foo") == ["a", "a/bar", "bar"])
    }
  }

  // Not from upstream: as in git, a file can't be re-included when its
  // parent directory is excluded.
  @Test func walkExcludedDirectoryNotReentered() {
    pending("walkExcludedDirectoryNotReentered") {
      let tree = [".gitignore": "build/\n!build/keep", "build/keep": "", "build/x": "", "src/a": ""]
      #expect(walk(tree, filenames: [".gitignore"]) == [".gitignore", "src", "src/a"])
    }
  }
}

// Walks a fake tree the way SSHadow enumerates: one directory at a time, never
// descending into ignored directories. Keys ending in "/" are directories;
// other keys are files mapped to their contents.
private func walk(_ tree: [String: String], filenames: [String], global: String = "") -> [String] {
  var dirs: Set<String> = [""]
  var files: [String: String] = [:]
  for (key, contents) in tree {
    let path = key.hasSuffix("/") ? String(key.dropLast()) : key
    if key.hasSuffix("/") { dirs.insert(path) } else { files[path] = contents }
    var parent = parentOf(path)
    while !parent.isEmpty {
      dirs.insert(parent)
      parent = parentOf(parent)
    }
  }

  func ignoreFiles(in dir: String) -> [String: String] {
    var found: [String: String] = [:]
    for name in filenames {
      found[name] = files[dir.isEmpty ? name : "\(dir)/\(name)"]
    }
    return found
  }

  var result: [String] = []
  func visit(_ dir: String, _ ignore: Ignore) {
    let entries = dirs.map { ($0, true) } + files.keys.map { ($0, false) }
    for (path, isDir) in entries where !path.isEmpty && parentOf(path) == dir {
      if ignore.matched(path, isDir: isDir).isIgnore { continue }
      result.append(path)
      if isDir {
        let name = String(path.split(separator: "/").last!)
        visit(path, ignore.child(name, files: ignoreFiles(in: path)))
      }
    }
  }
  visit("", Ignore(filenames: filenames, global: global, files: ignoreFiles(in: "")))
  return result.sorted()
}

private func parentOf(_ path: String) -> String {
  path.split(separator: "/").dropLast().joined(separator: "/")
}

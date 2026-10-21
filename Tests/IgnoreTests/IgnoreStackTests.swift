// Adapted from the dir.rs and walk.rs tests at
// https://github.com/BurntSushi/ripgrep/tree/020687a77d13146923333f0beb274eeabd54a270/crates/ignore/src

import Testing

@testable import Ignore

struct IgnoreStackTests {
  @Test func explicitIgnore() {
    let ignore = IgnoreStack(filenames: [], global: "foo\n!bar")
    #expect(ignore.matched("foo", isDirectory: false).isIgnored)
    #expect(ignore.matched("bar", isDirectory: false).isIncluded)
    #expect(ignore.matched("baz", isDirectory: false).isUnmatched)
  }

  @Test func customIgnore() {
    let ignore = IgnoreStack(filenames: [".customignore"], files: [".customignore": "foo\n!bar"])
    #expect(ignore.matched("foo", isDirectory: false).isIgnored)
    #expect(ignore.matched("bar", isDirectory: false).isIncluded)
    #expect(ignore.matched("baz", isDirectory: false).isUnmatched)
  }

  // Later filenames take precedence over earlier ones.
  @Test func customIgnorePrecedence() {
    let ignore = IgnoreStack(
      filenames: [".customignore1", ".customignore2"],
      files: [".customignore1": "foo", ".customignore2": "!foo"]
    )
    #expect(ignore.matched("foo", isDirectory: false).isIncluded)
  }

  // Adapted from exclude_lowest: global rules take the place of
  // .git/info/exclude as the lowest precedence.
  @Test func globalLowest() {
    let ignore = IgnoreStack(
      filenames: [".gitignore", ".customignore"],
      global: "foo\nbar\nbaz",
      files: [".gitignore": "!foo", ".customignore": "!bar"]
    )
    #expect(ignore.matched("baz", isDirectory: false).isIgnored)
    #expect(ignore.matched("foo", isDirectory: false).isIncluded)
    #expect(ignore.matched("bar", isDirectory: false).isIncluded)
  }

  @Test func notPresent() {
    let ignore = IgnoreStack(filenames: [".gitignore"])
    #expect(ignore.matched("foo", isDirectory: false).isUnmatched)
  }

  // Adapted from stops_at_git_dir, without the .git barrier.
  @Test func parentRulesApplyInChild() {
    let root = IgnoreStack(filenames: [".gitignore"], files: [".gitignore": "bar"])
    let foo = root.child("foo", files: [:])
    #expect(root.matched("bar", isDirectory: false).isIgnored)
    #expect(foo.matched("bar", isDirectory: false).isIgnored)
  }

  // Adapted from absolute_parent_anchored.
  @Test func anchoredToOwnDirectory() {
    let root = IgnoreStack(filenames: [".gitignore"], files: [".gitignore": "/llvm/\nfoo"])
    let src = root.child("src", files: [:])
    #expect(root.matched("llvm", isDirectory: true).isIgnored)
    #expect(src.matched("llvm", isDirectory: true).isUnmatched)
    #expect(src.matched("foo", isDirectory: false).isIgnored)
  }

  // Not from upstream.
  @Test func namesAreRelativeToTheirDirectory() {
    let root = IgnoreStack(
      filenames: [".gitignore"],
      files: [".gitignore": "/a.txt\nsrc/lib/b.txt"]
    )
    let lib = root.child("src", files: [:]).child("lib", files: [:])
    #expect(root.matched("a.txt", isDirectory: false).isIgnored)
    #expect(lib.matched("a.txt", isDirectory: false).isUnmatched)
    #expect(lib.matched("b.txt", isDirectory: false).isIgnored)
  }

  // Not from upstream.
  @Test func nearestDirectoryWins() {
    let root = IgnoreStack(filenames: [".gitignore"], files: [".gitignore": "*.log"])
    let src = root.child("src", files: [".gitignore": "!keep.log"])
    #expect(src.matched("keep.log", isDirectory: false).isIncluded)
    #expect(src.matched("other.log", isDirectory: false).isIgnored)
  }

  // Not from upstream.
  @Test func laterFilenameBeatsNearerDirectory() {
    let root = IgnoreStack(
      filenames: [".gitignore", ".sshadowignore"],
      files: [".sshadowignore": "!.env"]
    )
    let src = root.child("src", files: [".gitignore": ".env"])
    #expect(src.matched(".env", isDirectory: false).isIncluded)
  }

  @Test func walkNoIgnores() {
    let tree = ["a/b/c/": "", "x/y/": "", "a/b/foo": "", "x/y/foo": ""]
    #expect(
      walk(tree, filenames: [])
        == ["a", "a/b", "a/b/c", "a/b/foo", "x", "x/y", "x/y/foo"]
    )
  }

  @Test func walkCustomIgnore() {
    let tree = [".customignore": "foo", "foo": "", "a/foo": "", "bar": "", "a/bar": ""]
    #expect(
      walk(tree, filenames: [".customignore"]) == [".customignore", "a", "a/bar", "bar"]
    )
  }

  @Test func walkExplicitIgnore() {
    let tree = ["foo": "", "a/foo": "", "bar": "", "a/bar": ""]
    #expect(walk(tree, filenames: [], global: "foo") == ["a", "a/bar", "bar"])
  }

  // Not from upstream: as in git, a file can't be re-included when its
  // parent directory is excluded.
  @Test func walkExcludedDirectoryNotReentered() {
    let tree = [".gitignore": "build/\n!build/keep", "build/keep": "", "build/x": "", "src/a": ""]
    #expect(walk(tree, filenames: [".gitignore"]) == [".gitignore", "src", "src/a"])
  }
}

// Walks a fake tree the way SSHadow enumerates: one directory at a time, never
// descending into ignored directories. Keys ending in "/" are directories;
// other keys are files mapped to their contents.
func walk(_ tree: [String: String], filenames: [String], global: String = "") -> [String] {
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
  func visit(_ dir: String, _ ignore: IgnoreStack) {
    let entries = dirs.map { ($0, true) } + files.keys.map { ($0, false) }
    for (path, isDirectory) in entries where !path.isEmpty && parentOf(path) == dir {
      let name = String(path.split(separator: "/").last!)
      if ignore.matched(name, isDirectory: isDirectory).isIgnored { continue }
      result.append(path)
      if isDirectory {
        visit(path, ignore.child(name, files: ignoreFiles(in: path)))
      }
    }
  }
  visit("", IgnoreStack(filenames: filenames, global: global, files: ignoreFiles(in: "")))
  return result.sorted()
}

func parentOf(_ path: String) -> String {
  path.split(separator: "/").dropLast().joined(separator: "/")
}

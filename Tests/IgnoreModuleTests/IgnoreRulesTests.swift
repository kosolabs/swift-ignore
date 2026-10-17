// Ported from https://github.com/BurntSushi/ripgrep/blob/020687a77d13146923333f0beb274eeabd54a270/crates/ignore/src/gitignore.rs

import Testing

@testable import IgnoreModule

private let root = "/home/foobar/rust/rg"

struct MatchCase: CustomTestStringConvertible, Sendable {
  let name: String
  let root: String
  let gitignore: String
  let path: String
  let isDir: Bool

  init(_ name: String, _ root: String, _ gitignore: String, _ path: String, _ isDir: Bool = false) {
    self.name = name
    self.root = root
    self.gitignore = gitignore
    self.path = path
    self.isDir = isDir
  }

  var testDescription: String { name }
}

private let ignoredCases: [MatchCase] = [
  MatchCase("ig1", root, "months", "months"),
  MatchCase("ig2", root, "*.lock", "Cargo.lock"),
  MatchCase("ig3", root, "*.rs", "src/main.rs"),
  MatchCase("ig4", root, "src/*.rs", "src/main.rs"),
  MatchCase("ig5", root, "/*.c", "cat-file.c"),
  MatchCase("ig6", root, "/src/*.rs", "src/main.rs"),
  MatchCase("ig7", root, "!src/main.rs\n*.rs", "src/main.rs"),
  MatchCase("ig8", root, "foo/", "foo", true),
  MatchCase("ig9", root, "**/foo", "foo"),
  MatchCase("ig10", root, "**/foo", "src/foo"),
  MatchCase("ig11", root, "**/foo/**", "src/foo/bar"),
  MatchCase("ig12", root, "**/foo/**", "wat/src/foo/bar/baz"),
  MatchCase("ig13", root, "**/foo/bar", "foo/bar"),
  MatchCase("ig14", root, "**/foo/bar", "src/foo/bar"),
  MatchCase("ig15", root, "abc/**", "abc/x"),
  MatchCase("ig16", root, "abc/**", "abc/x/y"),
  MatchCase("ig17", root, "abc/**", "abc/x/y/z"),
  MatchCase("ig18", root, "a/**/b", "a/b"),
  MatchCase("ig19", root, "a/**/b", "a/x/b"),
  MatchCase("ig20", root, "a/**/b", "a/x/y/b"),
  MatchCase("ig21", root, "\\!xy", "!xy"),
  MatchCase("ig22", root, "\\#foo", "#foo"),
  MatchCase("ig23", root, "foo", "./foo"),
  MatchCase("ig24", root, "target", "grep/target"),
  MatchCase("ig25", root, "Cargo.lock", "./tabwriter-bin/Cargo.lock"),
  MatchCase("ig26", root, "/foo/bar/baz", "./foo/bar/baz"),
  MatchCase("ig27", root, "foo/", "xyz/foo", true),
  MatchCase("ig28", "./src", "/llvm/", "./src/llvm", true),
  MatchCase("ig29", root, "node_modules/ ", "node_modules", true),
  MatchCase("ig30", root, "**/", "foo/bar", true),
  MatchCase("ig31", root, "path1/*", "path1/foo"),
  MatchCase("ig32", root, ".a/b", ".a/b"),
  MatchCase("ig33", "./", ".a/b", ".a/b"),
  MatchCase("ig34", ".", ".a/b", ".a/b"),
  MatchCase("ig35", "./.", ".a/b", ".a/b"),
  MatchCase("ig36", "././", ".a/b", ".a/b"),
  MatchCase("ig37", "././.", ".a/b", ".a/b"),
  MatchCase("ig38", root, "\\[", "["),
  MatchCase("ig39", root, "\\?", "?"),
  MatchCase("ig40", root, "\\*", "*"),
  MatchCase("ig41", root, "\\a", "a"),
  MatchCase("ig42", root, "s*.rs", "sfoo.rs"),
  MatchCase("ig43", root, "**", "foo.rs"),
  MatchCase("ig44", root, "**/**/*", "a/foo.rs"),
  MatchCase("cs1", root, "*.html", "foo.html"),
]

private let notIgnoredCases: [MatchCase] = [
  MatchCase("ignot1", root, "amonths", "months"),
  MatchCase("ignot2", root, "monthsa", "months"),
  MatchCase("ignot3", root, "/src/*.rs", "src/grep/src/main.rs"),
  MatchCase("ignot4", root, "/*.c", "mozilla-sha1/sha1.c"),
  MatchCase("ignot5", root, "/src/*.rs", "src/grep/src/main.rs"),
  MatchCase("ignot6", root, "*.rs\n!src/main.rs", "src/main.rs"),
  MatchCase("ignot7", root, "foo/", "foo", false),
  MatchCase("ignot8", root, "**/foo/**", "wat/src/afoo/bar/baz"),
  MatchCase("ignot9", root, "**/foo/**", "wat/src/fooa/bar/baz"),
  MatchCase("ignot10", root, "**/foo/bar", "foo/src/bar"),
  MatchCase("ignot11", root, "#foo", "#foo"),
  MatchCase("ignot12", root, "\n\n\n", "foo"),
  MatchCase("ignot13", root, "foo/**", "foo", true),
  MatchCase(
    "ignot14",
    "./third_party/protobuf",
    "m4/ltoptions.m4",
    "./third_party/protobuf/csharp/src/packages/repositories.config"
  ),
  MatchCase("ignot15", root, "!/bar", "foo/bar"),
  MatchCase("ignot16", root, "*\n!**/", "foo", true),
  MatchCase("ignot17", root, "src/*.rs", "src/grep/src/main.rs"),
  MatchCase("ignot18", root, "path1/*", "path2/path1/foo"),
  MatchCase("ignot19", root, "s*.rs", "src/foo.rs"),
  MatchCase("cs2", root, "*.html", "foo.HTML"),
  MatchCase("cs3", root, "*.html", "foo.htm"),
  MatchCase("cs4", root, "*.html", "foo.HTM"),
]

// Tests expected to fail until the port is complete. Remove a name once its
// test passes; a pending test that passes is reported as a failure.
private let pendingTests: Set<String> = [
  "ig1", "ig2", "ig3", "ig4", "ig5", "ig6", "ig7", "ig8", "ig9", "ig10",
  "ig11", "ig12", "ig13", "ig14", "ig15", "ig16", "ig17", "ig18", "ig19", "ig20",
  "ig21", "ig22", "ig23", "ig24", "ig25", "ig26", "ig27", "ig28", "ig29", "ig30",
  "ig31", "ig32", "ig33", "ig34", "ig35", "ig36", "ig37", "ig38", "ig39", "ig40",
  "ig41", "ig42", "ig43", "ig44",
  "ignot1", "ignot2", "ignot3", "ignot4", "ignot5", "ignot6", "ignot7", "ignot8",
  "ignot9", "ignot10", "ignot11", "ignot12", "ignot13", "ignot14", "ignot15",
  "ignot16", "ignot17", "ignot18", "ignot19",
  "cs1", "cs2", "cs3", "cs4",
  "parseExcludesFile1", "parseExcludesFile2", "parseExcludesFile3",
  "parseExcludesFile4", "parseExcludesFile5",
  "regression106",
  "caseInsensitive",
]

private func pending(
  _ name: String,
  sourceLocation: SourceLocation = #_sourceLocation,
  _ body: () throws -> Void
) rethrows {
  try withKnownIssue("Not implemented yet", sourceLocation: sourceLocation) {
    try body()
  } when: {
    pendingTests.contains(name)
  }
}

private func rulesFromStr(_ root: String, _ s: String) throws -> IgnoreRules {
  var builder = IgnoreRulesBuilder(root: root)
  try builder.addStr(from: nil, s)
  return try builder.build()
}

struct IgnoreRulesTests {
  @Test(arguments: ignoredCases)
  func ignored(_ c: MatchCase) throws {
    try pending(c.name) {
      let rules = try rulesFromStr(c.root, c.gitignore)
      #expect(rules.matched(c.path, isDir: c.isDir).isIgnore)
    }
  }

  @Test(arguments: notIgnoredCases)
  func notIgnored(_ c: MatchCase) throws {
    try pending(c.name) {
      let rules = try rulesFromStr(c.root, c.gitignore)
      #expect(!rules.matched(c.path, isDir: c.isDir).isIgnore)
    }
  }

  @Test func parseExcludesFile1() throws {
    try pending("parseExcludesFile1") {
      let got = try #require(parseExcludesFile("[core]\nexcludesFile = /foo/bar"))
      #expect(got == "/foo/bar")
    }
  }

  @Test func parseExcludesFile2() throws {
    try pending("parseExcludesFile2") {
      let got = try #require(parseExcludesFile("[core]\nexcludesFile = ~/foo/bar"))
      #expect(got == expandTilde("~/foo/bar"))
    }
  }

  @Test func parseExcludesFile3() {
    pending("parseExcludesFile3") {
      #expect(parseExcludesFile("[core]\nexcludeFile = /foo/bar") == nil)
    }
  }

  @Test func parseExcludesFile4() throws {
    try pending("parseExcludesFile4") {
      let got = try #require(parseExcludesFile("[core]\nexcludesFile = \"~/foo/bar\""))
      #expect(got == expandTilde("~/foo/bar"))
    }
  }

  @Test func parseExcludesFile5() {
    pending("parseExcludesFile5") {
      #expect(parseExcludesFile("[core]\nexcludesFile = \" \"~/foo/bar \" \"") == nil)
    }
  }

  // See: https://github.com/BurntSushi/ripgrep/issues/106
  @Test func regression106() throws {
    try pending("regression106") {
      _ = try rulesFromStr("/", " ")
    }
  }

  @Test func caseInsensitive() throws {
    try pending("caseInsensitive") {
      var builder = IgnoreRulesBuilder(root: root)
      builder.caseInsensitive = true
      try builder.addStr(from: nil, "*.html")
      let rules = try builder.build()
      #expect(rules.matched("foo.html", isDir: false).isIgnore)
      #expect(rules.matched("foo.HTML", isDir: false).isIgnore)
      #expect(!rules.matched("foo.htm", isDir: false).isIgnore)
      #expect(!rules.matched("foo.HTM", isDir: false).isIgnore)
    }
  }
}

// Not from upstream.

import Testing

@testable import Ignore

private let gitignore = ".gitignore"

struct IgnoreTreeTests {
  @Test func unknownRootMatchesNothing() {
    let tree = IgnoreTree(filenames: [gitignore], global: "*.log")
    #expect(tree.matched("a.log", isDirectory: false) == nil)
    #expect(!tree.knows(""))
  }

  @Test func unknownDirectoryMatchesNothing() {
    var tree = IgnoreTree(filenames: [gitignore])
    tree.set([gitignore: "*.log"], in: "")
    #expect(tree.matched("a.log", isDirectory: false)?.isIgnored == true)
    #expect(tree.matched("src/a.log", isDirectory: false) == nil)
  }

  @Test func knownDirectoryWithoutFilesUsesParentRules() {
    var tree = IgnoreTree(filenames: [gitignore])
    tree.set([gitignore: "*.log"], in: "")
    tree.set([:], in: "src")
    #expect(tree.knows("src"))
    #expect(tree.matched("src/a.log", isDirectory: false)?.isIgnored == true)
    #expect(tree.matched("src/a.txt", isDirectory: false) == Match.unmatched)
  }

  @Test func ignoredParentIgnoresEverythingBelow() {
    var tree = IgnoreTree(filenames: [gitignore])
    tree.set([gitignore: "data/"], in: "")
    let match = tree.matched("data/sub/a.txt", isDirectory: false)
    guard case .ignored(let rule)? = match else {
      Issue.record("expected an ignore match, got \(String(describing: match))")
      return
    }
    #expect(rule.file == gitignore)
    #expect(rule.original == "data/")
  }

  @Test func excludedDirectoryCantBeReincluded() {
    var tree = IgnoreTree(filenames: [gitignore])
    tree.set([gitignore: "build/\n!build/keep"], in: "")
    tree.set([gitignore: "!keep"], in: "build")
    #expect(tree.matched("build/keep", isDirectory: false)?.isIgnored == true)
  }

  @Test func includedParentDoesNotStopMatching() {
    var tree = IgnoreTree(filenames: [gitignore])
    tree.set([gitignore: "*\n!src/\n!*.c"], in: "")
    tree.set([:], in: "src")
    #expect(tree.matched("src/main.c", isDirectory: false)?.isIncluded == true)
    #expect(tree.matched("src/main.o", isDirectory: false)?.isIgnored == true)
  }

  @Test func rulesAreAnchoredToTheirDirectory() {
    var tree = IgnoreTree(filenames: [gitignore])
    tree.set([:], in: "")
    tree.set([gitignore: "/a"], in: "src")
    tree.set([:], in: "src/lib")
    #expect(tree.matched("src/a", isDirectory: false)?.isIgnored == true)
    #expect(tree.matched("src/lib/a", isDirectory: false) == Match.unmatched)
  }

  @Test func ruleReportsItsFile() {
    var tree = IgnoreTree(filenames: [gitignore])
    tree.set([:], in: "")
    tree.set([:], in: "src")
    tree.set([gitignore: "*.log"], in: "src/lib")
    guard case .ignored(let rule)? = tree.matched("src/lib/a.log", isDirectory: false) else {
      Issue.record("expected an ignore match")
      return
    }
    #expect(rule.file == "src/lib/\(gitignore)")
  }

  @Test func nearestDirectoryWins() {
    var tree = IgnoreTree(filenames: [gitignore])
    tree.set([gitignore: "*.log"], in: "")
    tree.set([gitignore: "!keep.log"], in: "src")
    #expect(tree.matched("src/keep.log", isDirectory: false)?.isIncluded == true)
    #expect(tree.matched("src/other.log", isDirectory: false)?.isIgnored == true)
  }

  @Test func laterFilenameBeatsNearerDirectory() {
    var tree = IgnoreTree(filenames: [gitignore, ".sshadowignore"])
    tree.set([".sshadowignore": "!.env"], in: "")
    tree.set([gitignore: ".env"], in: "src")
    #expect(tree.matched("src/.env", isDirectory: false)?.isIncluded == true)
  }

  @Test func globalRulesComeLast() {
    var tree = IgnoreTree(filenames: [gitignore], global: "foo\nbar")
    tree.set([gitignore: "!foo"], in: "")
    #expect(tree.matched("foo", isDirectory: false)?.isIncluded == true)
    #expect(tree.matched("bar", isDirectory: false)?.isIgnored == true)
  }

  @Test func directoryOnlyRulesSkipFiles() {
    var tree = IgnoreTree(filenames: [gitignore])
    tree.set([gitignore: "out/"], in: "")
    #expect(tree.matched("out", isDirectory: true)?.isIgnored == true)
    #expect(tree.matched("out", isDirectory: false) == Match.unmatched)
  }

  @Test func setReportsChanges() {
    var tree = IgnoreTree(filenames: [gitignore])
    let changes = [
      tree.set([:], in: ""),
      tree.set([gitignore: "*.log"], in: ""),
      tree.set([gitignore: "*.log"], in: ""),
      tree.set([gitignore: "*.tmp"], in: ""),
      tree.set([:], in: ""),
      tree.set([gitignore: "*.log"], in: "src"),
    ]
    #expect(changes == [false, true, false, true, true, true])
  }

  @Test func unlistedFilenamesAreSkipped() {
    var tree = IgnoreTree(filenames: [gitignore])
    let changed = tree.set([".other": "*"], in: "")
    #expect(!changed)
    #expect(tree.knows(""))
    #expect(tree.matched("a", isDirectory: false) == Match.unmatched)
  }

  @Test func removeForgetsFile() {
    var tree = IgnoreTree(filenames: [gitignore, ".sshadowignore"])
    tree.set([gitignore: "*.log", ".sshadowignore": "*.tmp"], in: "")
    let removed = [
      tree.remove(gitignore, in: ""),
      tree.remove(gitignore, in: ""),
      tree.remove(gitignore, in: "src"),
    ]
    #expect(removed == [true, false, false])
    #expect(tree.knows(""))
    #expect(tree.matched("a.log", isDirectory: false) == Match.unmatched)
    #expect(tree.matched("a.tmp", isDirectory: false)?.isIgnored == true)
  }

  @Test func filesReturnsWhatWasSet() {
    var tree = IgnoreTree(filenames: [gitignore])
    #expect(tree.files(in: "") == nil)
    tree.set([gitignore: "*.log", ".other": "*"], in: "")
    tree.set([:], in: "src")
    #expect(tree.files(in: "") == [gitignore: "*.log"])
    #expect(tree.files(in: "src") == [:])
    #expect(tree.files(in: "src/lib") == nil)
  }

  @Test func directoryPathsAreNormalized() {
    var tree = IgnoreTree(filenames: [gitignore])
    tree.set([:], in: "")
    tree.set([gitignore: "*.log"], in: "/src/lib/")
    #expect(tree.knows("src/lib"))
    #expect(tree.knows("src/lib/"))
  }

  @Test func copiesAreIndependent() {
    var tree = IgnoreTree(filenames: [gitignore])
    tree.set([gitignore: "*.log"], in: "")
    let before = tree
    tree.set([:], in: "")
    #expect(before.matched("a.log", isDirectory: false)?.isIgnored == true)
    #expect(tree.matched("a.log", isDirectory: false) == Match.unmatched)
  }

  @Test func agreesWithWalk() {
    let files = [
      ".gitignore": "*.log\nbuild/\n!keep.log",
      ".sshadowignore": "secrets/",
      "a.log": "", "keep.log": "", "notes.txt": "",
      "build/out": "", "build/.gitignore": "!out",
      "src/.gitignore": "/gen\n!*.log\n*.tmp",
      "src/a.log": "", "src/b.tmp": "", "src/main.c": "", "src/gen/x": "",
      "src/lib/gen/y": "", "src/lib/c.tmp": "", "src/lib/.sshadowignore": "!c.tmp",
      "secrets/key": "", "docs/secrets/key": "", "docs/secrets/.gitignore": "!key",
    ]
    let filenames = [".gitignore", ".sshadowignore"]
    let walked = Set(walk(files, filenames: filenames, global: "*.swp"))

    var dirs: Set<String> = [""]
    for path in files.keys {
      var parent = parentOf(path)
      while !parent.isEmpty {
        dirs.insert(parent)
        parent = parentOf(parent)
      }
    }
    var tree = IgnoreTree(filenames: filenames, global: "*.swp")
    for dir in dirs {
      var found: [String: String] = [:]
      for name in filenames {
        found[name] = files[dir.isEmpty ? name : "\(dir)/\(name)"]
      }
      tree.set(found, in: dir)
    }

    let entries = dirs.subtracting([""]).map { ($0, true) } + files.keys.map { ($0, false) }
    for (path, isDirectory) in entries {
      let ignored = tree.matched(path, isDirectory: isDirectory)?.isIgnored == true
      #expect(ignored == !walked.contains(path), "\(path)")
    }
  }
}

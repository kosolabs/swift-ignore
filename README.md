# swift-ignore

Gitignore-style ignore rules for Swift, built for [SSHadow](https://github.com/kosolabs/sshadow).

The `Ignore` module matches paths against rules written in `.gitignore` syntax, combining ignore files across a directory tree. It reads no files itself: you pass in the contents of the ignore files you find, as you find them.

## ⚠️ Pre-1.0

This package is functional, but **breaking changes may occur between minor releases until version 1.0.** Pin to a minor version:

```swift
.package(url: "https://github.com/kosolabs/swift-ignore.git", .upToNextMinor(from: "0.2.0"))
```

## Example

```swift
import Ignore

var tree = IgnoreTree(filenames: [".gitignore", ".sshadowignore"], global: ".DS_Store")
tree.set([".gitignore": "build/\n*.log"], in: "")
tree.matched("build/out/a.o", isDirectory: false)?.isIgnored   // true: build/ is ignored
tree.matched("notes.txt", isDirectory: false)?.isUnmatched     // true
tree.matched("src/debug.log", isDirectory: false)              // nil: src isn't known yet

tree.set([".sshadowignore": "!debug.log"], in: "src")          // true: the rules changed
tree.matched("src/debug.log", isDirectory: false)?.isIncluded  // true: later filenames win

if case .ignored(let rule)? = tree.matched("src/error.log", isDirectory: false) {
  print(rule.file ?? "global", rule.original)                   // .gitignore *.log
}
```

`set` records the ignore files in a directory and returns whether they changed, and `remove` drops one. `matched` takes a path from the root. As in git, a path inside an ignored directory is ignored by that directory's rule and can't be re-included. `matched` returns nil until every directory on the way has been `set`, because their rules could change the answer.

## Attribution

This is a Swift port of the [`ignore`](https://github.com/BurntSushi/ripgrep/tree/master/crates/ignore) crate from [ripgrep](https://github.com/BurntSushi/ripgrep), by Andrew Gallant. Its tests are adapted from the crate's own tests. The `ignore` crate is dual-licensed under the Unlicense and MIT; this port uses it under MIT, with its notice in [LICENSE-ripgrep](LICENSE-ripgrep).

## License

MIT. See [LICENSE](LICENSE).

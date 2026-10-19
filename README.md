# swift-ignore

Gitignore-style ignore rules for Swift, built for [SSHadow](https://github.com/kosolabs/sshadow).

`IgnoreModule` matches paths against rules written in `.gitignore` syntax and combines ignore files across a directory tree. It reads no files itself: you pass in the contents of the ignore files you find.

## ⚠️ Pre-1.0

This package is functional, but **breaking changes may occur between minor releases until version 1.0.** Pin to a minor version:

```swift
.package(url: "https://github.com/kosolabs/swift-ignore.git", .upToNextMinor(from: "0.1.0"))
```

## Example

```swift
import IgnoreModule

let root = Ignore(
  filenames: [".gitignore", ".sshadowignore"],
  global: ".DS_Store",
  files: [".gitignore": "build/\n*.log"]
)
root.matched("build", isDir: true).isIgnore        // true
root.matched("notes.txt", isDir: false).isIgnore   // false

let src = root.child("src", files: [".sshadowignore": "!debug.log"])
src.matched("debug.log", isDir: false).isWhitelist  // true: later filenames win
src.matched("error.log", isDir: false).isIgnore     // true
```

`matched` takes the name of an entry in that `Ignore`'s directory. Don't descend into ignored directories: as in git, a file inside an excluded directory can't be re-included.

## Attribution

This is a Swift port of the [`ignore`](https://github.com/BurntSushi/ripgrep/tree/master/crates/ignore) crate from [ripgrep](https://github.com/BurntSushi/ripgrep), by Andrew Gallant. Its tests are adapted from the crate's own tests. The `ignore` crate is dual-licensed under the Unlicense and MIT; this port uses it under MIT, with its notice in [LICENSE-ripgrep](LICENSE-ripgrep).

## License

MIT. See [LICENSE](LICENSE).

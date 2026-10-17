# swift-ignore

Gitignore-style ignore rules for Swift, built for [SSHadow](https://github.com/kosolabs/sshadow).

`IgnoreModule` matches paths against rules written in `.gitignore` syntax and combines ignore files across a directory tree. It reads no files itself: you pass in the contents of the ignore files you find.

This package is a work in progress.

## Attribution

This is a Swift port of the [`ignore`](https://github.com/BurntSushi/ripgrep/tree/master/crates/ignore) crate from [ripgrep](https://github.com/BurntSushi/ripgrep), by Andrew Gallant. Its tests are adapted from the crate's own tests. The `ignore` crate is dual-licensed under the Unlicense and MIT.

Where ripgrep and git disagree, this package follows git. For example, `{a,b}` is a literal name, not a list of alternatives.

## License

MIT. See [LICENSE](LICENSE).

# swift-ignore

A Swift port of ripgrep's `ignore` crate, built for SSHadow's `.sshadowignore` files. Users choose which ignore filenames apply (for example `.sshadowignore` and `.gitignore`) and can set connection-wide rules.

## Goal

Behave the way someone who knows `.gitignore` expects. Prefer simple over 100% correct. Ripgrep compatibility is not a goal: where ripgrep and git disagree, follow git. Where git's behavior would surprise a user, prefer the unsurprising behavior, and cover the difference with a test marked as differing from git.

Check git's behavior with `git check-ignore --no-index -v` in a scratch repo, and see `man gitignore`. `check-ignore` also reports a path when one of its parent directories matches, so it can't answer glob-level questions. For those, git's `wildmatch()` with `WM_PATHNAME` is the reference.

## Decisions

Out of scope, on purpose:

- `require_git`. Ignore files apply whether or not a `.git` directory exists.
- Rules from directories above the root.
- Reading the user's global gitignore or git config.
- Hidden-file filtering.
- File I/O. Callers pass ignore file contents in.
- Pattern errors. Nothing in gitignore syntax is invalid, so builders don't throw.

Matching semantics:

- Braces are literal: `{a,b}` matches a file named `{a,b}`.
- Match on `Character`s. `?` and `[...]` match one user-perceived character, and NFC and NFD forms compare equal. Git matches bytes.
- Case-insensitive matching folds Unicode case. Git folds ASCII only.
- `*`, `?` and `[...]` never match `/`. A `**` that isn't between slashes (or at the start or end) acts like `*`.
- An unclosed `[`, an unknown POSIX class or a trailing backslash makes the pattern never match.
- POSIX classes like `[[:digit:]]` are supported.

API:

- The module is `IgnoreModule`, so the `Ignore` type doesn't shadow it.
- `IgnoreRules`, built with `IgnoreRulesBuilder`, holds the rules from one ignore file. It's ripgrep's `Gitignore`.
- `Ignore` combines ignore files across a directory tree. It's ripgrep's `dir::Ignore`. `Ignore(filenames:global:files:)` is the root, and `child(_:files:)` descends one directory.
- `Match<T>` (`.none`, `.ignore`, `.whitelist`) and `Glob` report which rule matched.
- Paths are `/`-separated `String`s, relative to the root of the `Ignore` stack.
- Precedence:
  - Later entries in `filenames` beat earlier ones.
  - Within one filename, the nearest directory wins.
  - `global` rules come last.
- Callers never descend into an ignored directory, so a file inside an excluded directory can't be re-included.

Internals can change freely. Ask before changing the public API.

## Upstream

Pinned to commit `020687a77d13146923333f0beb274eeabd54a270` of https://github.com/BurntSushi/ripgrep:

- `crates/ignore/src/gitignore.rs`: rule parsing and matching.
- `crates/ignore/src/dir.rs`: the directory stack.
- `crates/ignore/src/pathutil.rs`: path helpers.
- `crates/globset/src/glob.rs`: glob semantics. Its `matches!`/`nmatches!` tests are the starting point for glob tests.

The code is MIT-licensed. Keep `LICENSE-ripgrep`, and keep the "Ported from" or "Adapted from" header on files that come from upstream.

## Tests

- Run `swift test`. Filter with `swift test --filter IgnoreRulesTests`.
- Done means `swift test` exits 0 with no warnings.
- The case tables in `IgnoreRulesTests.swift` match upstream exactly. Don't edit them. If a ported test conflicts with git's behavior, stop and flag it instead of changing it.
- Mark tests that aren't from upstream with a `// Not from upstream` comment.
- Prefer unit tests. Tests that run `git` are fine as a check against git's behavior.

`Tests/IgnoreModuleTests/Pending.swift` lists tests that are expected to fail until the port is complete. Each listed test runs inside `withKnownIssue`, so it passes while failing. A pending test that starts passing fails with "Known issue was not recorded". When that happens, remove its name. Only remove names: never add a name to make a failing test pass.

## Conventions

- Swift 6 language mode and Swift Testing.
- 2-space indentation.
- Sparse comments: no multi-line explanations of why.
- Prefer `Sendable` value types.
- Ask before adding package dependencies.
- One branch and PR per piece of work, off `main`.
- PR titles are conventional commits (`feat:`, `fix:`, `test:`, `refactor:`, `docs:`, `chore:`). PRs are squash-merged, and release-please releases from `feat:` and `fix:` titles.
- CI runs `swift test` on macOS for pull requests to `main`.

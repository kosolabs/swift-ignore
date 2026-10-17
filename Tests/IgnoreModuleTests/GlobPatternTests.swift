// Adapted from the matches!/nmatches! tests in
// https://github.com/BurntSushi/ripgrep/blob/020687a77d13146923333f0beb274eeabd54a270/crates/globset/src/glob.rs
// Expected results come from git's wildmatch with WM_PATHNAME, not globset.

import Testing

@testable import IgnoreModule

struct GlobCase: CustomTestStringConvertible, Sendable {
  let name: String
  let pattern: String
  let path: String
  let caseInsensitive: Bool

  init(_ name: String, _ pattern: String, _ path: String, caseInsensitive: Bool = false) {
    self.name = name
    self.pattern = pattern
    self.path = path
    self.caseInsensitive = caseInsensitive
  }

  var testDescription: String { name }
}

private let matchCases: [GlobCase] = [
  GlobCase("match1", "a", "a"),
  GlobCase("match2", "a*b", "a_b"),
  GlobCase("match3", "a*b*c", "abc"),
  GlobCase("match4", "a*b*c", "a_b_c"),
  GlobCase("match5", "a*b*c", "a___b___c"),
  GlobCase("match6", "abc*abc*abc", "abcabcabcabcabcabcabc"),
  GlobCase("match7", "a*a*a*a*a*a*a*a*a", "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
  GlobCase("match8", "a*b[xyz]c*d", "abxcdbxcddd"),
  GlobCase("match9", "*.rs", ".rs"),
  GlobCase("match10", "☃", "☃"),
  GlobCase("matchrec1", "some/**/needle.txt", "some/needle.txt"),
  GlobCase("matchrec2", "some/**/needle.txt", "some/one/needle.txt"),
  GlobCase("matchrec3", "some/**/needle.txt", "some/one/two/needle.txt"),
  GlobCase("matchrec4", "some/**/needle.txt", "some/other/needle.txt"),
  GlobCase("matchrec5", "**", "abcde"),
  GlobCase("matchrec6", "**", ""),
  GlobCase("matchrec7", "**", ".asdf"),
  GlobCase("matchrec8", "**", "/x/.asdf"),
  GlobCase("matchrec9", "some/**/**/needle.txt", "some/needle.txt"),
  GlobCase("matchrec10", "some/**/**/needle.txt", "some/one/needle.txt"),
  GlobCase("matchrec11", "some/**/**/needle.txt", "some/one/two/needle.txt"),
  GlobCase("matchrec12", "some/**/**/needle.txt", "some/other/needle.txt"),
  GlobCase("matchrec13", "**/test", "one/two/test"),
  GlobCase("matchrec14", "**/test", "one/test"),
  GlobCase("matchrec15", "**/test", "test"),
  GlobCase("matchrec16", "/**/test", "/one/two/test"),
  GlobCase("matchrec17", "/**/test", "/one/test"),
  GlobCase("matchrec18", "/**/test", "/test"),
  GlobCase("matchrec19", "**/.*", ".abc"),
  GlobCase("matchrec20", "**/.*", "abc/.abc"),
  GlobCase("matchrec21", "**/foo/bar", "foo/bar"),
  GlobCase("matchrec22", ".*/**", ".abc/abc"),
  GlobCase("matchrec23", "test/**", "test/"),
  GlobCase("matchrec24", "test/**", "test/one"),
  GlobCase("matchrec25", "test/**", "test/one/two"),
  GlobCase("matchrec26", "some/*/needle.txt", "some/one/needle.txt"),
  GlobCase("matchrange1", "a[0-9]b", "a0b"),
  GlobCase("matchrange2", "a[0-9]b", "a9b"),
  GlobCase("matchrange3", "a[!0-9]b", "a_b"),
  GlobCase("matchrange4", "[a-z123]", "1"),
  GlobCase("matchrange5", "[1a-z23]", "1"),
  GlobCase("matchrange6", "[123a-z]", "1"),
  GlobCase("matchrange7", "[abc-]", "-"),
  GlobCase("matchrange8", "[-abc]", "-"),
  GlobCase("matchrange9", "[-a-c]", "b"),
  GlobCase("matchrange10", "[a-c-]", "b"),
  GlobCase("matchrange11", "[-]", "-"),
  GlobCase("matchrange12", "a[^0-9]b", "a_b"),
  GlobCase("matchpat1", "*hello.txt", "hello.txt"),
  GlobCase("matchpat2", "*hello.txt", "gareth_says_hello.txt"),
  GlobCase("matchpat4", "*hello.txt", "some\\path\\to\\hello.txt"),
  GlobCase("matchpat6", "*some/path/to/hello.txt", "some/path/to/hello.txt"),
  GlobCase("matchescape", "_[[]_[]]_[?]_[*]_!_", "_[_]_?_*_!_"),
  GlobCase("matchcasei1", "aBcDeFg", "aBcDeFg", caseInsensitive: true),
  GlobCase("matchcasei2", "aBcDeFg", "abcdefg", caseInsensitive: true),
  GlobCase("matchcasei3", "aBcDeFg", "ABCDEFG", caseInsensitive: true),
  GlobCase("matchcasei4", "aBcDeFg", "AbCdEfG", caseInsensitive: true),
  GlobCase("matchalt1", "a,b", "a,b"),
  GlobCase("matchalt2", ",", ","),
  GlobCase("matchslash1", "abc/def", "abc/def"),
  GlobCase("matchbackslash1", "\\[", "["),
  GlobCase("matchbackslash2", "\\?", "?"),
  GlobCase("matchbackslash3", "\\*", "*"),
  GlobCase("matchbackslash7", "\\a", "a"),

  // Not from upstream.
  GlobCase("bytes2", "??.txt", "é.txt"),
  GlobCase("posix1", "[[:digit:]]", "5"),
  GlobCase("posix3", "[[:alpha:][:digit:]]", "x"),
  GlobCase("posix4", "[![:digit:]]", "x"),
  GlobCase("starstar1", "a**", "abc"),
  GlobCase("starstar4", "a/**b", "a/xb"),
  GlobCase("casei6", "[A-Z]", "q", caseInsensitive: true),
  GlobCase("casei7", "[a-z]", "Q", caseInsensitive: true),
  GlobCase("bracket1", "[]]", "]"),
  GlobCase("bracket2", "[!]]", "a"),
  GlobCase("empty1", "*", ""),
]

private let nonMatchCases: [GlobCase] = [
  GlobCase("matchalt15", "foo{,.txt}", "foo"),
  GlobCase("matchslash2", "abc?def", "abc/def"),
  GlobCase("matchslash3", "abc*def", "abc/def"),
  GlobCase("matchslash5", "abc\\def", "abc/def"),
  GlobCase("matchnot1", "a*b*c", "abcd"),
  GlobCase("matchnot2", "abc*abc*abc", "abcabcabcabcabcabcabca"),
  GlobCase("matchnot3", "some/**/needle.txt", "some/other/notthis.txt"),
  GlobCase("matchnot4", "some/**/**/needle.txt", "some/other/notthis.txt"),
  GlobCase("matchnot5", "/**/test", "test"),
  GlobCase("matchnot6", "/**/test", "/one/notthis"),
  GlobCase("matchnot7", "/**/test", "/notthis"),
  GlobCase("matchnot8", "**/.*", "ab.c"),
  GlobCase("matchnot9", "**/.*", "abc/ab.c"),
  GlobCase("matchnot10", ".*/**", "a.bc"),
  GlobCase("matchnot11", ".*/**", "abc/a.bc"),
  GlobCase("matchnot12", "a[0-9]b", "a_b"),
  GlobCase("matchnot13", "a[!0-9]b", "a0b"),
  GlobCase("matchnot14", "a[!0-9]b", "a9b"),
  GlobCase("matchnot15", "[!-]", "-"),
  GlobCase("matchnot16", "*hello.txt", "hello.txt-and-then-some"),
  GlobCase("matchnot17", "*hello.txt", "goodbye.txt"),
  GlobCase("matchnot18", "*some/path/to/hello.txt", "some/path/to/hello.txt-and-then-some"),
  GlobCase("matchnot19", "*some/path/to/hello.txt", "some/other/path/to/hello.txt"),
  GlobCase("matchnot20", "a", "foo/a"),
  GlobCase("matchnot21", "./foo", "foo"),
  GlobCase("matchnot22", "**/foo", "foofoo"),
  GlobCase("matchnot23", "**/foo/bar", "foofoo/bar"),
  GlobCase("matchnot24", "/*.c", "mozilla-sha1/sha1.c"),
  GlobCase("matchnot25", "*.c", "mozilla-sha1/sha1.c"),
  GlobCase("matchnot26", "**/m4/ltoptions.m4", "csharp/src/packages/repositories.config"),
  GlobCase("matchnot27", "a[^0-9]b", "a0b"),
  GlobCase("matchnot28", "a[^0-9]b", "a9b"),
  GlobCase("matchnot29", "[^-]", "-"),
  GlobCase("matchnot30", "some/*/needle.txt", "some/needle.txt"),
  GlobCase("matchrec31", "some/*/needle.txt", "some/one/two/needle.txt"),
  GlobCase("matchrec32", "some/*/needle.txt", "some/one/two/three/needle.txt"),
  GlobCase("matchrec33", ".*/**", ".abc"),
  GlobCase("matchrec34", "foo/**", "foo"),

  // globset matches these because its `*` matches `/` by default.
  GlobCase("matchpat3", "*hello.txt", "some/path/to/hello.txt"),
  GlobCase("matchpat5", "*hello.txt", "/an/absolute/path/to/hello.txt"),
  GlobCase("matchpat7", "*some/path/to/hello.txt", "a/bigger/some/path/to/hello.txt"),

  // globset matches these because it treats braces as alternation.
  GlobCase("matchalt3", "{a,b}", "a"),
  GlobCase("matchalt4", "{a,b}", "b"),
  GlobCase("matchalt5", "{**/src/**,foo}", "abc/src/bar"),
  GlobCase("matchalt6", "{**/src/**,foo}", "foo"),
  GlobCase("matchalt7", "{[}],foo}", "}"),
  GlobCase("matchalt8", "{foo}", "foo"),
  GlobCase("matchalt9", "{}", ""),
  GlobCase("matchalt10", "{,}", ""),
  GlobCase("matchalt11", "{*.foo,*.bar,*.wat}", "test.foo"),
  GlobCase("matchalt12", "{*.foo,*.bar,*.wat}", "test.bar"),
  GlobCase("matchalt13", "{*.foo,*.bar,*.wat}", "test.wat"),
  GlobCase("matchalt14", "foo{,.txt}", "foo.txt"),
  GlobCase("matchalt17", "{a,b{c,d}}", "bc"),
  GlobCase("matchalt18", "{a,b{c,d}}", "bd"),
  GlobCase("matchalt19", "{a,b{c,d}}", "a"),

  // globset matches this; git's classes never match `/`.
  GlobCase("matchslash4", "abc[/]def", "abc/def"),

  // Not from upstream.
  GlobCase("bytes1", "?.txt", "é.txt"),
  GlobCase("unclosed1", "[", "["),
  GlobCase("unclosed2", "a[", "a["),
  GlobCase("unclosed3", "[a", "[a"),
  GlobCase("posix2", "[[:alpha:]]", "5"),
  GlobCase("posix5", "[[:bogus:]]", "b"),
  GlobCase("starstar2", "a**", "a/b"),
  GlobCase("starstar3", "**a", "x/a"),
  GlobCase("starstar5", "a/**b", "a/x/b"),
  GlobCase("casei5", "É", "é", caseInsensitive: true),
  GlobCase("trailingbackslash1", "abc\\", "abc\\"),
  GlobCase("trailingbackslash2", "abc\\", "abc"),
  GlobCase("bracket3", "[!]]", "]"),
  GlobCase("slash1", "*", "a/b"),
  GlobCase("slash2", "a?b", "a/b"),
  GlobCase("slash3", "[a-c]", "/"),
  GlobCase("slash4", "[!a]", "/"),
]

struct GlobPatternTests {
  @Test(arguments: matchCases)
  func matches(_ c: GlobCase) {
    pending(c.name) {
      #expect(GlobPattern(c.pattern, caseInsensitive: c.caseInsensitive).matches(c.path))
    }
  }

  @Test(arguments: nonMatchCases)
  func doesNotMatch(_ c: GlobCase) {
    pending(c.name) {
      #expect(!GlobPattern(c.pattern, caseInsensitive: c.caseInsensitive).matches(c.path))
    }
  }
}

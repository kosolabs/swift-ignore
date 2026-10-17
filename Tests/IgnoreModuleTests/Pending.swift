import Testing

// Tests expected to fail until the port is complete. Remove a name once its
// test passes; a pending test that passes is reported as a failure.
private let pendingTests: Set<String> = [
  // IgnoreRulesTests
  "ig1", "ig2", "ig3", "ig4", "ig5", "ig6", "ig7", "ig8", "ig9", "ig10",
  "ig11", "ig12", "ig13", "ig14", "ig15", "ig16", "ig17", "ig18", "ig19", "ig20",
  "ig21", "ig22", "ig23", "ig24", "ig25", "ig26", "ig27", "ig28", "ig29", "ig30",
  "ig31", "ig32", "ig33", "ig34", "ig35", "ig36", "ig37", "ig38", "ig39", "ig40",
  "ig41", "ig42", "ig43", "ig44",
  "cs1",
  "caseInsensitive",
  "bracesAreLiteral",

  // IgnoreTests
  "explicitIgnore", "customIgnore", "customIgnorePrecedence", "globalLowest",
  "parentRulesApplyInChild", "anchoredToOwnDirectory",
  "nearestDirectoryWins",
  "walkCustomIgnore", "walkExplicitIgnore",
  "walkExcludedDirectoryNotReentered",

  // GlobPatternTests
  "match1", "match2", "match3", "match4", "match5", "match6", "match7",
  "match8", "match9", "match10", "matchrec1", "matchrec2", "matchrec3",
  "matchrec4", "matchrec5", "matchrec6", "matchrec7", "matchrec8", "matchrec9",
  "matchrec10", "matchrec11", "matchrec12", "matchrec13", "matchrec14",
  "matchrec15", "matchrec16", "matchrec17", "matchrec18", "matchrec19",
  "matchrec20", "matchrec21", "matchrec22", "matchrec23", "matchrec24",
  "matchrec25", "matchrec26", "matchrange1", "matchrange2", "matchrange3",
  "matchrange4", "matchrange5", "matchrange6", "matchrange7", "matchrange8",
  "matchrange9", "matchrange10", "matchrange11", "matchrange12", "matchpat1",
  "matchpat2", "matchpat4", "matchpat6", "matchescape", "matchcasei1",
  "matchcasei2", "matchcasei3", "matchcasei4", "matchalt1", "matchalt2",
  "matchslash1", "matchbackslash1", "matchbackslash2", "matchbackslash3",
  "matchbackslash7", "bytes2", "posix1", "posix3", "posix4", "starstar1",
  "starstar4", "casei6", "casei7", "bracket1", "bracket2", "empty1",
]

func pending(
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

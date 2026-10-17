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

import Testing

// Tests expected to fail until the port is complete. Remove a name once its
// test passes; a pending test that passes is reported as a failure.
private let pendingTests: Set<String> = [
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

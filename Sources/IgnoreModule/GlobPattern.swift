struct GlobPattern: Sendable {
  private let tokens: [Token]?
  private let caseInsensitive: Bool

  init(_ pattern: String, caseInsensitive: Bool = false) {
    self.tokens = Self.parse(Array(pattern))
    self.caseInsensitive = caseInsensitive
  }

  func matches(_ path: String) -> Bool {
    guard let tokens else { return false }
    let text = Array(path)
    var next = [Bool](repeating: false, count: text.count + 1)
    next[text.count] = true
    var cur = next
    for token in tokens.reversed() {
      var dirs = false
      for t in stride(from: text.count, through: 0, by: -1) {
        let more = t < text.count
        switch token {
        case .literal(let l):
          cur[t] = more && equal(text[t], l) && next[t + 1]
        case .any:
          cur[t] = more && text[t] != "/" && next[t + 1]
        case .class(let cls):
          cur[t] =
            more && text[t] != "/" && cls.contains(text[t], caseInsensitive: caseInsensitive)
            && next[t + 1]
        case .star:
          cur[t] = next[t] || (more && text[t] != "/" && cur[t + 1])
        case .anything:
          cur[t] = next[t] || (more && cur[t + 1])
        case .directories:
          dirs = dirs || (more && text[t] == "/" && next[t + 1])
          cur[t] = next[t] || dirs
        }
      }
      swap(&cur, &next)
    }
    return next[0]
  }

  private func equal(_ a: Character, _ b: Character) -> Bool {
    a == b || (caseInsensitive && a.lowercased() == b.lowercased())
  }

  private static func parse(_ p: [Character]) -> [Token]? {
    var tokens: [Token] = []
    var i = 0
    while i < p.count {
      switch p[i] {
      case "\\":
        guard i + 1 < p.count else { return nil }
        tokens.append(.literal(p[i + 1]))
        i += 2
      case "?":
        tokens.append(.any)
        i += 1
      case "[":
        guard let (cls, end) = CharClass.parse(p, from: i + 1) else { return nil }
        tokens.append(.class(cls))
        i = end
      case "*":
        var end = i + 1
        while end < p.count && p[end] == "*" { end += 1 }
        let atStart = i == 0 || p[i - 1] == "/"
        if end - i >= 2 && atStart && end < p.count && p[end] == "/" {
          tokens.append(.directories)
          i = end + 1
        } else if end - i >= 2 && atStart && end == p.count {
          tokens.append(.anything)
          i = end
        } else {
          tokens.append(.star)
          i = end
        }
      default:
        tokens.append(.literal(p[i]))
        i += 1
      }
    }
    return tokens
  }
}

private enum Token: Sendable {
  case literal(Character)
  case any
  case `class`(CharClass)
  case star
  case anything
  case directories
}

private struct CharClass: Sendable {
  enum Item: Sendable {
    case single(Character)
    case range(ClosedRange<Character>)
    case posix(Posix)
  }

  let negated: Bool
  let items: [Item]

  func contains(_ c: Character, caseInsensitive: Bool) -> Bool {
    var candidates = [c]
    if caseInsensitive {
      for s in [c.lowercased(), c.uppercased()] where s.count == 1 {
        candidates.append(Character(s))
      }
    }
    let found = candidates.contains { candidate in
      items.contains { item in
        switch item {
        case .single(let s): s == candidate
        case .range(let r): r.contains(candidate)
        case .posix(let posix): posix.contains(candidate)
        }
      }
    }
    return found != negated
  }

  static func parse(_ p: [Character], from start: Int) -> (CharClass, Int)? {
    var i = start
    var negated = false
    if i < p.count && (p[i] == "!" || p[i] == "^") {
      negated = true
      i += 1
    }
    var items: [Item] = []
    var first = true
    while i < p.count {
      if p[i] == "]" && !first {
        return (CharClass(negated: negated, items: items), i + 1)
      }
      first = false
      if p[i] == "[" && i + 1 < p.count && p[i + 1] == ":",
        let close = closeOfPosix(p, from: i + 2)
      {
        guard let posix = Posix(rawValue: String(p[(i + 2)..<close])) else { return nil }
        items.append(.posix(posix))
        i = close + 2
        continue
      }
      guard let (lo, afterLo) = member(p, at: i) else { return nil }
      if afterLo + 1 < p.count && p[afterLo] == "-" && p[afterLo + 1] != "]" {
        guard let (hi, afterHi) = member(p, at: afterLo + 1) else { return nil }
        if lo <= hi { items.append(.range(lo...hi)) }
        i = afterHi
      } else {
        items.append(.single(lo))
        i = afterLo
      }
    }
    return nil
  }

  private static func member(_ p: [Character], at i: Int) -> (Character, Int)? {
    guard i < p.count else { return nil }
    if p[i] == "\\" {
      guard i + 1 < p.count else { return nil }
      return (p[i + 1], i + 2)
    }
    return (p[i], i + 1)
  }

  private static func closeOfPosix(_ p: [Character], from start: Int) -> Int? {
    var i = start
    while i + 1 < p.count {
      if p[i] == ":" && p[i + 1] == "]" { return i }
      if p[i] == "]" { return nil }
      i += 1
    }
    return nil
  }
}

private enum Posix: String, Sendable {
  case alnum, alpha, blank, cntrl, digit, graph, lower, print, punct, space, upper, xdigit

  func contains(_ c: Character) -> Bool {
    switch self {
    case .alnum: c.isLetter || c.wholeNumberValue != nil
    case .alpha: c.isLetter
    case .blank: c == " " || c == "\t"
    case .cntrl: c.unicodeScalars.first?.properties.generalCategory == .control
    case .digit: c.wholeNumberValue != nil
    case .graph: !c.isWhitespace && !Posix.cntrl.contains(c)
    case .lower: c.isLowercase
    case .print: c == " " || Posix.graph.contains(c)
    case .punct: c.isPunctuation || c.isSymbol
    case .space: c.isWhitespace
    case .upper: c.isUppercase
    case .xdigit: c.isHexDigit
    }
  }
}

pub type ParseError {
  UnknownDirective(line: String)
  SyntaxError(line: String)
  UnknownChord(line: String)
}

pub fn describe(error: ParseError) {
  case error {
    SyntaxError(line) -> "Syntax error on line " <> line
    UnknownChord(line) -> "Unknown chord on line " <> line
    UnknownDirective(line) -> "Unknown directive on line " <> line
  }
}

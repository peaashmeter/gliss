pub type ParseError {
  UnknownDirective(line: String)
  MissingDirective(line: String)
  SyntaxError(line: String)
  UnknownChord(line: String)
}

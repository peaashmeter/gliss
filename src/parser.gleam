import gleam/list
import gleam/result
import gleam/string
import parse_error
import term

pub fn parse_source(source: String) {
  use parsed <- result.try(
    split_by_lines(source)
    |> parse_lines([]),
  )
  parsed |> Ok
}

fn split_by_lines(source: String) {
  source
  |> string.split("\n")
  |> list.map(fn(s) { s |> string.trim_start })
  |> list.map(strip_comment)
  |> list.filter(fn(s) { !string.is_empty(s) })
}

fn parse_lines(lines: List(String), terms: List(term.TrackTerm)) {
  case lines {
    [x, ..xs] ->
      case parse_line(x) {
        Ok(t) -> parse_lines(xs, [t, ..terms])
        Error(e) -> e |> Error
      }
    [] -> terms |> list.reverse |> Ok
  }
}

fn parse_line(line: String) {
  case line {
    "@" <> term -> {
      case term {
        "tempo" <> arg -> term.parse(arg, line, term.tempo_parser)
        "instrument" <> arg -> term.parse(arg, line, term.instrument_parser)
        _ -> parse_error.UnknownDirective(line) |> Error
      }
    }
    _ -> term.parse(line, line, term.chordline_parser)
  }
}

fn strip_comment(line: String) {
  case line |> string.split_once("//") {
    Error(_) -> line
    Ok(#(line, _)) -> line |> string.trim
  }
}

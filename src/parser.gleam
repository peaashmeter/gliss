import chord
import gleam/function
import gleam/list
import gleam/result
import gleam/string
import parse_error
import term

pub fn parse_source(source: String) {
  use parsed <- result.try(
    split_by_lines(source)
    |> list.map(strip_comment)
    |> parse_lines([]),
  )
  parsed |> Ok
}

fn split_by_lines(source: String) {
  source
  |> string.split("\n")
  |> list.map(fn(s) { s |> string.trim_start })
  |> list.filter(fn(s) { !string.is_empty(s) })
}

fn parse_lines(lines: List(String), terms: List(term.TrackTerm)) {
  case lines {
    [x, ..xs] ->
      case parse_line(x) |> list.try_map(function.identity) {
        Ok(ts) ->
          parse_lines(
            xs,
            ts
              |> list.fold(terms, list.prepend),
          )
        Error(e) -> e |> Error
      }
    [] -> terms |> list.reverse |> Ok
  }
}

fn parse_line(line: String) {
  case line {
    "@" <> term -> {
      case term {
        "tempo" <> arg -> [term.parse_tempo(arg)]
        "instrument" <> arg -> [term.parse_instrument(arg)]
        _ -> [parse_error.UnknownDirective(line) |> Error]
      }
    }
    _ ->
      line
      |> chord.parse_chords_line
      |> list.map(fn(chord) {
        chord |> chord.parse_chord |> result.map(term.Chord)
      })
  }
}

fn strip_comment(line: String) {
  case line |> string.split_once("#") {
    Error(_) -> line
    Ok(#(line, _)) -> line |> string.trim
  }
}

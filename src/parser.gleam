import chord
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import parse_error
import term.{type Term, Instrument, Tempo, Title, Track}

pub fn parse_source(source: String) {
  use parsed <- result.try(
    split_by_lines(source)
    |> parse_lines(None, [], []),
  )
  parsed |> list.map(clean_arguments) |> parse_args
}

fn parse_args(terms: List(#(Term, String))) {
  terms
  |> list.try_map(fn(t) {
    let #(term, arg) = t
    case term {
      Instrument(_) -> {
        case int.parse(arg) {
          Error(_) -> parse_error.SyntaxError(arg) |> Error
          Ok(id) -> Instrument(id) |> Ok
        }
      }
      Tempo(_) -> {
        case int.parse(arg) {
          Error(_) -> parse_error.SyntaxError(arg) |> Error
          Ok(tempo) -> Tempo(tempo) |> Ok
        }
      }
      Title(_) -> Title(arg) |> Ok
      Track(_) -> {
        use chords <- result.try(
          arg |> chord.parse_chords_line |> list.try_map(chord.parse_chord),
        )
        chords |> Track |> Ok
      }
    }
  })
}

fn split_by_lines(source: String) {
  source
  |> string.split("\n")
  |> list.map(fn(s) { s |> string.trim_start })
  |> list.filter(fn(s) { !string.is_empty(s) })
}

fn parse_lines(
  lines: List(String),
  last_term: Option(Term),
  arg_acc: List(String),
  terms: List(#(Term, List(String))),
) -> Result(List(#(Term, List(String))), parse_error.ParseError) {
  case lines {
    [x, ..xs] ->
      case x {
        // Term declaration
        "@" <> term -> {
          // Close the latest term and start proccessing a new one
          let closed = case last_term {
            None -> terms
            Some(t) -> [#(t, arg_acc), ..terms]
          }

          case term {
            "title" <> arg ->
              parse_lines(xs, Some(term.new_title()), [arg], closed)
            "tempo" <> arg ->
              parse_lines(xs, Some(term.new_tempo()), [arg], closed)
            "instrument" <> arg ->
              parse_lines(xs, Some(term.new_instrument()), [arg], closed)
            "track" <> arg ->
              parse_lines(xs, Some(term.new_track()), [arg], closed)
            _ -> Error(parse_error.UnknownDirective(line: x))
          }
        }
        // Comment line, skip this
        "#" <> _ -> parse_lines(xs, last_term, arg_acc, terms)
        // Treat as the argument of the latest term
        arg ->
          case last_term {
            None -> Error(parse_error.MissingDirective(line: x))
            Some(_) -> parse_lines(xs, last_term, [arg, ..arg_acc], terms)
          }
      }
    [] ->
      Ok(case last_term {
        None -> terms
        Some(t) -> [#(t, arg_acc), ..terms]
      })
  }
}

fn clean_arguments(term: #(Term, List(String))) {
  #(
    term.0,
    term.1
      |> list.map(string.trim)
      |> list.filter(fn(s) { !string.is_empty(s) })
      |> list.reverse
      |> string.join("\n"),
  )
}

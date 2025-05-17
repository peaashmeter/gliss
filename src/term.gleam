import gleam/int
import gleam/string
import parse_error

pub type TrackTerm {
  Tempo(value: Int)
  Instrument(value: Int)
  Chord(value: #(List(Int), Float))
}

pub fn parse_tempo(str: String) {
  let trimmed = str |> string.trim
  case trimmed |> int.parse {
    Error(_) -> parse_error.SyntaxError(str) |> Error
    Ok(bpm) -> Tempo(bpm) |> Ok
  }
}

pub fn parse_instrument(str: String) {
  let trimmed = str |> string.trim
  case trimmed |> int.parse {
    Error(_) -> parse_error.SyntaxError(str) |> Error
    Ok(bpm) -> Instrument(bpm) |> Ok
  }
}

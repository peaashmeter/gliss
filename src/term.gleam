import chord
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import parse_error

pub type TrackTerm {
  Tempo(value: Int)
  Instrument(value: Int)
  ChordLine(value: List(#(List(Int), Float)))
}

pub fn parse(
  arg: String,
  context: String,
  parser: fn(String) -> Result(TrackTerm, Nil),
) {
  arg |> parser |> result.map_error(fn(_) { parse_error.SyntaxError(context) })
}

pub fn tempo_parser(str: String) {
  let trimmed = str |> string.trim
  case trimmed |> int.parse {
    Error(_) -> Nil |> Error
    Ok(bpm) -> Tempo(bpm) |> Ok
  }
}

pub fn instrument_parser(str: String) {
  let trimmed = str |> string.trim
  case trimmed |> int.parse {
    Error(_) -> Nil |> Error
    Ok(bpm) -> Instrument(bpm) |> Ok
  }
}

pub fn chordline_parser(str: String) {
  let parsed =
    str
    |> chord.parse_chords_line
    |> list.map(fn(chord) { chord |> chord.parse_chord })
    |> result.all

  case parsed {
    Error(_) -> Nil |> Error
    Ok(chords) -> ChordLine(chords) |> Ok
  }
}

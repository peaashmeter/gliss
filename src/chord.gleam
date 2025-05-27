import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import parse_error

const chord_octave = 4

pub type Chord {
  Chord(duration: String, data: String)
  RawChord(duration: String, notes: List(String))
  Rest(duration: String)
}

pub fn parse_chords_line(line: String) -> List(Chord) {
  parse_chords_line_step(line |> string.to_graphemes, [])
}

fn parse_chords_line_step(chars: List(String), acc: List(Chord)) {
  let trimmed =
    chars
    |> list.drop_while(is_empty)

  case trimmed {
    [] -> acc |> list.reverse
    ["[", ..chord] -> {
      let inner = chord |> list.take_while(fn(char) { char != "]" })
      let rest =
        chord |> list.drop_while(fn(char) { char != "]" }) |> list.drop(1)
      let #(duration, rest) = rest |> parse_duration
      parse_chords_line_step(rest, [
        case inner {
          [] -> Rest(duration |> string.concat)
          __ -> Chord(duration |> string.concat, inner |> string.concat)
        },
        ..acc
      ])
    }
    ["(", ..chord] -> {
      let inner = chord |> list.take_while(fn(char) { char != ")" })
      let rest =
        chord |> list.drop_while(fn(char) { char != ")" }) |> list.drop(1)
      let #(duration, rest) = rest |> parse_duration
      parse_chords_line_step(rest, [
        case inner {
          [] -> Rest(duration |> string.concat)
          _ ->
            RawChord(
              duration |> string.concat,
              inner
                |> string.concat
                |> string.split(",")
                |> list.map(string.trim),
            )
        },
        ..acc
      ])
    }
    _ -> panic as "How did we get here?"
  }
}

fn parse_duration(chars: List(String)) {
  case chars {
    [":", ..rest] -> {
      let duration =
        rest
        |> list.take_while(is_not_empty)
      let rest = rest |> list.drop(duration |> list.length)
      #(duration, rest)
    }
    _ -> #(["1"], chars)
  }
}

fn is_empty(char) {
  char |> string.trim |> string.is_empty
}

fn is_not_empty(char) {
  !is_empty(char)
}

pub fn parse_chord(chord: Chord) {
  use duration <- result.try(
    chord.duration
    |> parse_number
    |> result.map_error(fn(_) { parse_error.SyntaxError(chord.duration) }),
  )
  case chord {
    Chord(_, data) -> {
      use split <- result.try(split_chord(data))
      use midipoints <- result.try(split |> map_chord)
      #(midipoints, duration) |> Ok
    }
    RawChord(_, notes) -> {
      use split <- result.try(notes |> list.try_map(split_chord))
      use midipoints <- result.try(
        split
        |> list.map(fn(pair) {
          let #(semitone, octave) = pair
          use octave <- result.try(
            int.parse(octave)
            |> result.map_error(fn(_) { parse_error.SyntaxError(octave) }),
          )
          semitone |> to_midi_pitch(octave) |> Ok
        })
        |> result.all,
      )

      #(midipoints, duration) |> Ok
    }
    Rest(_) -> #([], duration) |> Ok
  }
}

fn split_chord(chord: String) {
  case chord {
    "B#" <> rest -> Ok(#(0, rest))
    "C#" <> rest | "Db" <> rest -> Ok(#(1, rest))
    "D#" <> rest | "Eb" <> rest -> Ok(#(3, rest))
    "Fb" <> rest -> Ok(#(4, rest))
    "E#" <> rest -> Ok(#(5, rest))
    "F#" <> rest | "Gb" <> rest -> Ok(#(6, rest))
    "G#" <> rest | "Ab" <> rest -> Ok(#(8, rest))
    "A#" <> rest | "Bb" <> rest -> Ok(#(10, rest))
    "Cb" <> rest -> Ok(#(11, rest))
    "C" <> rest -> Ok(#(0, rest))
    "D" <> rest -> Ok(#(2, rest))
    "E" <> rest -> Ok(#(4, rest))
    "F" <> rest -> Ok(#(5, rest))
    "G" <> rest -> Ok(#(7, rest))
    "A" <> rest -> Ok(#(9, rest))
    "B" <> rest -> Ok(#(11, rest))
    _ -> Error(parse_error.SyntaxError(chord))
  }
}

fn to_midi_pitch(semitone, octave) {
  12 * { octave + 1 } + semitone
}

fn map_chord(chord: #(Int, String)) {
  let #(root, suffix) = chord

  use #(suffix, bass) <- result.try(suffix |> split_bass)
  use suffix_notes <- result.try(suffix |> map_suffix)

  let notes =
    [root, ..suffix_notes |> list.map(int.add(_, root))]
    |> list.map(to_midi_pitch(_, chord_octave))
  case bass {
    option.None -> notes |> Ok
    option.Some(bass) ->
      [bass |> to_midi_pitch(chord_octave - 1), ..notes] |> Ok
  }
}

fn map_suffix(suffix: String) {
  case suffix {
    "" -> Ok([4, 7])
    "m" -> Ok([3, 7])
    "dim" -> Ok([3, 6])
    "aug" -> Ok([4, 8])
    "sus2" -> Ok([2, 7])
    "sus4" -> Ok([5, 7])
    "-5" -> Ok([4, 6])
    "6" -> Ok([4, 7, 9])
    "m6" -> Ok([3, 7, 9])
    "7" -> Ok([4, 7, 10])
    "m7" -> Ok([3, 7, 10])
    "dim7" -> Ok([3, 6, 9])
    "maj7" -> Ok([4, 7, 11])
    "mmaj7" -> Ok([3, 7, 11])
    "add9" -> Ok([4, 7, 14])
    "madd9" -> Ok([3, 7, 14])
    "add11" -> Ok([4, 7, 17])
    "madd11" -> Ok([3, 7, 17])
    "add13" -> Ok([4, 7, 21])
    "madd13" -> Ok([3, 7, 21])
    _ -> Error(parse_error.UnknownChord(suffix))
  }
}

/// Splits a chord suffix with bass as in maj7/C into #("maj7", "C")
fn split_bass(suffix: String) {
  case suffix |> string.split_once("/") {
    Error(_) -> #(suffix, option.None) |> Ok
    Ok(#(chord, bass)) -> {
      case bass |> split_chord {
        Ok(#(note, _)) -> {
          #(chord, note |> option.Some)
          |> Ok
        }

        Error(e) -> Error(e)
      }
    }
  }
}

fn parse_number(number: String) {
  case number |> int.parse {
    Error(_) ->
      case number |> float.parse {
        Error(_) -> Nil |> Error
        Ok(f) -> f |> Ok
      }
    Ok(n) -> n |> int.to_float |> Ok
  }
}

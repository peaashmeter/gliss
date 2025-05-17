import gleam/bit_array
import gleam/float
import gleam/int
import gleam/list
import term

const ticks_per_beat: Int = 480

pub fn build_midi(track: List(term.TrackTerm)) -> BitArray {
  let track_events =
    track
    |> list.map(fn(term) {
      case term {
        term.Chord(c) -> add_chord(c)
        term.Instrument(ins) -> [program_change(ins)]
        term.Tempo(bpm) -> [set_tempo(bpm)]
      }
    })
    |> list.flatten
    |> build_track

  [midi_header(), track_events, end_of_track()] |> bit_array.concat
}

fn midi_header() -> BitArray {
  <<"MThd":utf8, 6:32, 0:16, 1:16, ticks_per_beat:16>>
}

fn track_header(track_data: BitArray) -> BitArray {
  let track_length = bit_array.byte_size(track_data)
  <<"MTrk":utf8, track_length:32>> |> bit_array.append(track_data)
}

fn set_tempo(bpm: Int) -> BitArray {
  let micros = 60_000_000
  let tempo = micros / bpm

  let b1 = int.bitwise_shift_right(tempo, 16) |> int.bitwise_and(0xFF)
  let b2 = int.bitwise_shift_right(tempo, 8) |> int.bitwise_and(0xFF)
  let b3 = tempo |> int.bitwise_and(0xFF)

  <<0:8, 0xFF:8, 0x51:8, 0x03:8, b1:8, b2:8, b3:8>>
}

fn program_change(program: Int) -> BitArray {
  <<0:8, 0xC0:8, program:8>>
}

fn note_on(note: Int, velocity: Int) -> BitArray {
  <<0:8, 0x90:8, note:8, velocity:8>>
}

fn note_off(note: Int, velocity: Int, delay: Int) -> BitArray {
  let delta = encode_varlen(delay)
  let message = <<0x80:8, note:8, velocity:8>>
  <<delta:bits, message:bits>>
}

fn end_of_track() -> BitArray {
  <<0:8, 0xFF:8, 0x2F:8, 0x00:8>>
}

fn build_track(events: List(BitArray)) -> BitArray {
  let body = events |> bit_array.concat
  track_header(body)
}

fn add_chord(chord: #(List(Int), Float)) -> List(BitArray) {
  let #(notes, duration) = chord
  let ticks = float.round(duration *. { ticks_per_beat |> int.to_float })

  let ons = notes |> list.map(note_on(_, 90))

  let offs = case notes {
    [] -> []
    [first, ..rest] -> {
      let first_off = note_off(first, 90, ticks)
      let rest_offs = rest |> list.map(note_off(_, 90, 0))
      [first_off, ..rest_offs]
    }
  }

  ons |> list.append(offs)
}

fn encode_varlen(value: Int) -> BitArray {
  let base = case value {
    0 -> [0]
    _ -> build_chunks(value, [])
  }

  let tagged = tag_bytes(base)

  encode_bytes(tagged)
}

fn build_chunks(n: Int, acc: List(Int)) -> List(Int) {
  case n {
    0 -> acc
    _ -> {
      let chunk = int.bitwise_and(n, 0x7F)
      build_chunks(int.bitwise_shift_right(n, 7), [chunk, ..acc])
    }
  }
}

// Помечаем все байты кроме последнего флагом 0x80
fn tag_bytes(bytes: List(Int)) -> List(Int) {
  case bytes {
    [] -> []
    [only] -> [only]
    [head, ..tail] -> [int.bitwise_or(head, 0x80), ..tag_bytes(tail)]
  }
}

fn encode_bytes(bytes: List(Int)) -> BitArray {
  case bytes {
    [] -> <<>>
    [x, ..xs] -> <<x:8, encode_bytes(xs):bits>>
  }
}

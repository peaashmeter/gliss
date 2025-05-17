import midi
import parser
import simplifile
import term.{Instrument, Tempo, Title, Track}

const str = "
  @title Test
  @tempo 60
  @instrument 1
 
  # hello world
  @track
  (C3, C4):0.33 (D4):0.33 (Eb4):0.33
  (D3, D4):0.33 (Eb4):0.33 (F4):0.33
  (Eb3, Eb4):0.33 (F4):0.33 (G4):0.3
  (C3, C4, Eb4, G4, C5)
"

pub fn main() {
  //let _ = simplifile.create_file("./output.midi")
  case parser.parse_source(str) {
    Ok([Track(track), Instrument(ins), Tempo(bpm), _]) -> {
      midi.build_midi(track, ins, bpm)
      |> simplifile.write_bits("./output.midi", _)
      |> echo
    }
    _ -> todo
  }
}

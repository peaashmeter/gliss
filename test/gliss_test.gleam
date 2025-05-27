import gleam/list
import gleeunit
import gleeunit/should
import parser
import term

const source = "
    @instrument 1
    @tempo 100
    [Cmaj7/A]:2 (C4, E4, G4, B4):2
    (C2):0.33 (C#2):0.33
    (D2) (D#2)
    (E2) (E#2)
    // @instrument 16
    @instrument 10 //comment
    (F2) (F#2)
    (G2):10 (G#2):1
    (A2) (A#2)
    @tempo 60
    (B2) (B#2)
"

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn correct_syntax_test() {
  parser.parse_source(source)
  |> should.be_ok
  |> list.length
  |> should.equal(12)

  parser.parse_source(source)
  |> should.be_ok
  |> list.last
  |> should.be_ok
  |> should.equal(term.ChordLine([#([47], 1.0), #([36], 1.0)]))
}

const no_argument_source = "
    @instrument 1
    @tempo
    [Cmaj7]:2 (C4, E4, G4, B4):2
    (C2):0.33 (C#2):0.33
    (D2) (D#2)
    (E2) (E#2)
    //comment
    @instrument 10 //comment
    (F2) (F#2)
    (G2):10 (G#2):1
    (A2) (A#2)
    @tempo 60
    (B2) (B#2)
"

pub fn no_argument_source_test() {
  {
    parser.parse_source(no_argument_source)
    |> should.be_error
  }.line
  |> should.equal("@tempo")
}

const no_bracket_source = "
    @instrument 1
    @tempo 100
    [Cmaj7 (C4, E4, G4, B4):2
    (C2):0.33 (C#2):0.33
    (D2) (D#2)
    (E2) (E#2)
    //comment
    @instrument 10 //comment
    (F2) (F#2)
    (G2):10 (G#2):1
    (A2) (A#2)
    @tempo 60
    (B2) (B#2)
"

pub fn no_bracket_source_test() {
  {
    parser.parse_source(no_bracket_source)
    |> should.be_error
  }.line
  |> should.equal("[Cmaj7 (C4, E4, G4, B4):2")
}

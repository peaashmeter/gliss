pub type Term {
  Title(data: String)
  Tempo(data: Int)
  Instrument(data: Int)
  Track(data: List(#(List(Int), Float)))
}

pub fn new_title() {
  Title("Some Chords")
}

pub fn new_tempo() {
  Tempo(120)
}

pub fn new_instrument() {
  Instrument(0)
}

pub fn new_track() {
  Track([])
}

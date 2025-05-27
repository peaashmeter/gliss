import gleam/io
import gleam/result.{try}
import gleam/string
import midi
import parse_error
import parser
import shellout
import simplifile

pub fn main() {
  let status = case shellout.arguments() {
    [in, out] -> {
      use source <- try(simplifile.read(in) |> result.map_error(string.inspect))
      use ast <- try(
        parser.parse_source(source) |> result.map_error(parse_error.describe),
      )
      let midi = midi.build_midi(ast)

      midi
      |> simplifile.write_bits(out, _)
      |> result.map_error(string.inspect)
    }

    _ -> "Usage: gliss <source> <output.mid>" |> Error
  }

  case status {
    Error(reason) -> {
      reason |> io.println
      shellout.exit(1)
    }
    Ok(_) -> Nil
  }
}

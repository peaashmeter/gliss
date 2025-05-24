# Gliss
A simple language/command-line tool to generate (kind of) working Type 0 MIDI, written in Gleam!

## How do I create some tunes?
1) Write the code into a file (.gliss, I suppose).
    - Use `@tempo <bpm>` to set tempo
    - Use `@instrument <id>` to set instrument like in General MIDI
    - `#` marks a comment for your own convenience (does not affect the result at all!)
    - Use square brackets `[]` to write chords (like `[Cmaj7]`). You can check the list of available chords in the src/chord/map_suffix for now.
    - Use parentheses `()` to create chords from scratch (like `(C4, E4, G4, B4)`). You may use that syntax for single notes, too.
    - Add durations to your chords with `:<duration>` (like `[Cmaj7]:2`). No duration means a duration of one beat.
    - Use empty chords `[]`/`()` to add a rest.
    - Also check the example in `example/example.gliss`
2) Compile the MIDI using the following command:
    `gliss <source> <output.mid>`
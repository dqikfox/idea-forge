# smart-toy

Smart toy template for idea-forge.

Generates project structure, configuration, and make targets for a smart-toy product that ships:
- an embedded Python personality engine (the "brain" that runs on the device)
- a Pi-side Rust runtime (hardware control: servos, LEDs, audio, sensors)
- a training/eval pipeline (the "corpus" that gives the toy its character)
- a static website (marketing + docs at thelummings.com-style)

Combines naturally with: python-research (brain + training), rust-workspace (device runtime), static-website (marketing), notebook-laboratory (persona research).

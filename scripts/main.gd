# NicNacks

This repository contains a Godot 4 playable prototype of the NickNacks first-playable loop.

Features implemented in the current prototype:
- Drag blocks from the palette onto a 12x12 grid.
- Basic placement validation using corner contact and wall touches.
- Starting block, undo, and rotate controls.
- Marble spawn and collection logic.
- Simple score and track-progression scaffolding.

Open `main.tscn` in Godot 4.7+ to play.

This prototype intentionally focuses on the first playable rules from the design document rather than the full production systems.

Note: The repository includes the provided block and marble art under `Blocks/` and `Marbles/`, and the scripts load those assets directly from those folders.

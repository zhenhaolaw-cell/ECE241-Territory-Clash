# Territory Clash — User Manual (Milestone 2 placement demo)

This build shows character selection and placement. Battle is not connected yet.

## Setup
1. Plug a PS/2 mouse into the DE1-SoC and a VGA monitor into the VGA port.
2. Open `TerritoryClash.qpf` in Quartus, compile, and program the board.
3. The background, title and 16x16 grid appear on the monitor.

## Controls
| Control | Use |
|---|---|
| KEY[0] | Reset (restart from character selection) |
| KEY[1] | Confirm the character on the switches |
| SW[3:0] | Character ID (0–15) |
| Mouse move | Move the yellow highlight over the grid |
| Left click | Place a cell on the highlighted square |

## How to play the demo
1. **Reset:** press KEY[0]. Wait for the grid to finish drawing.
2. **Blue picks a character:** set SW[3:0] to an ID and press KEY[1].
3. **Red picks a character:** set SW[3:0] to an ID and press KEY[1].
4. **Blue places 5 cells:** move the mouse and left-click 5 empty squares. Each one turns blue.
5. **Red places 5 cells:** after blue's 5th cell the turn passes to red. Click 5 empty squares. Each one turns red.
6. **Done:** LEDR[9] lights. Press KEY[0] to play again.

Rules shown in the demo:
- Clicking a square that is already taken does nothing.
- Each player can place exactly 5 cells. Extra clicks are ignored.
- Clicks made while the screen is redrawing (a fraction of a millisecond) are ignored.

## Status LEDs
| LEDR[3:0] | Game state |
|---|---|
| 0000 | Starting up |
| 0001 | Blue selecting |
| 0010 | Red selecting |
| 0011 | Blue placing |
| 0100 | Red placing |

LEDR[9] = placement finished.

## Known limits of this demo
- The text bar at the bottom is mostly blank: the font only has the letters A and 0 so far.
- The battle phase (expansion, captures, winner) is not included in this build.

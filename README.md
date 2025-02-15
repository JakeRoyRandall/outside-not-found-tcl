# 404: Outside Not Found

`404: Outside Not Found` is a fictional, 2020-inspired terminal escape-room created retrospectively in September 2026. Its author and calendar dates are deliberately assigned project art, not a historical work record.

You are trapped in a four-room apartment with a frozen video call and a houseplant who has become your manager. Reconnect the call by exploring, collecting the right objects, and using them in the right room.

Run it with the installed Tcl 8.5 interpreter:

```sh
/usr/bin/tclsh app/game.tcl
```

Commands: `look`, `examine TARGET`, `go ROOM`, `take ITEM`, `use ITEM`, `inventory`, `journal`, `hint`, `undo`, `save PATH`, `load PATH`, `restart`, `help`, `quit`. `examine` inspects only a visible fixture in the current room or an item you carry; aliases such as `video`/`call` and `cup`/`mug` are accepted, and descriptions adapt to puzzle progress. `journal` records only observed clues, current carrying items, objectives already completed, and the hint count; it does not reveal unseen puzzle solutions. Its progress is derived from the same bounded state used by save/load, so restart clears it and load restores it. `hint` gives two progressive nudges for the current puzzle step, and the winning line reports successful moves and hints used. Successful `go`, `take`, and `use` actions add a snapshot to an undo history capped at 20 entries. `undo` restores room, inventory, puzzle flags, and move count; hint usage never decreases, and invalid, informational, and hint commands do not create history entries. A successful `restart` or `load` clears the undo history. Save files are bounded, versioned Tcl dict data; they are never sourced or evaluated. Paths are one token with no spaces. The parser treats player input as data and never evaluates it as Tcl code. EOF closes the session safely.

Run tests:

```sh
/usr/bin/tclsh tests/test_game.tcl
```

# 404: Outside Not Found

`404: Outside Not Found` is a fictional, 2020-inspired terminal escape-room created retrospectively in September 2026. Its author and calendar dates are deliberately assigned project art, not a historical work record.

You are trapped in a four-room apartment with a frozen video call and a houseplant who has become your manager. Reconnect the call by exploring, collecting the right objects, and using them in the right room.

Run it with the installed Tcl 8.5 interpreter:

```sh
/usr/bin/tclsh app/game.tcl
```

Commands: `look`, `go ROOM`, `take ITEM`, `use ITEM`, `inventory`, `journal`, `hint`, `save PATH`, `load PATH`, `restart`, `help`, `quit`. `journal` records only observed clues, current carrying items, and objectives already completed; it does not reveal unseen puzzle solutions. Its progress is derived from the same bounded state used by save/load, so restart clears it and load restores it. `hint` gives two progressive nudges for the current puzzle step, and the winning line reports successful moves and hints used. Save files are bounded, versioned Tcl dict data; they are never sourced or evaluated. Paths are one token with no spaces. The parser treats player input as data and never evaluates it as Tcl code. EOF closes the session safely.

Run tests:

```sh
/usr/bin/tclsh tests/test_game.tcl
```

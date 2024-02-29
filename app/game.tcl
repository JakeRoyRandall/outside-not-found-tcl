#!/usr/bin/env tclsh

namespace eval Game {
    variable room living
    variable inventory {}
    variable plantAwake 0
    variable routerOnline 0
    variable callLive 0
    variable mugAvailable 1
    variable cableAvailable 1
    variable hintDepth 0
    variable hintsUsed 0
    variable moves 0
    variable undoStack {}
    variable commandHistory {}
    variable transcriptChannel ""

    proc reset {} {
        variable room; variable inventory; variable plantAwake; variable routerOnline; variable callLive; variable mugAvailable; variable cableAvailable; variable hintDepth; variable hintsUsed; variable moves; variable undoStack; variable commandHistory
        set room living; set inventory {}; set plantAwake 0; set routerOnline 0; set callLive 0; set mugAvailable 1; set cableAvailable 1; set hintDepth 0; set hintsUsed 0; set moves 0; set undoStack {}; set commandHistory {}; catch {unset ::Game::hintStage}
    }
    proc say {text} { variable transcriptChannel; puts $text; if {$transcriptChannel ne ""} { puts $transcriptChannel $text; flush $transcriptChannel } }
    proc sayWithTranscript {text transcriptText} { variable transcriptChannel; puts $text; if {$transcriptChannel ne ""} { puts $transcriptChannel $transcriptText; flush $transcriptChannel } }
    proc openTranscript {path} { variable transcriptChannel; if {$path eq ""} { return }; set transcriptChannel [open $path {WRONLY CREAT EXCL}]; fconfigure $transcriptChannel -encoding utf-8 -translation lf }
    proc closeTranscript {} { variable transcriptChannel; if {$transcriptChannel ne ""} { catch {close $transcriptChannel}; set transcriptChannel "" } }
    proc has {item} { variable inventory; expr {[lsearch -exact $inventory $item] >= 0} }
    proc add {item} { variable inventory; if {![has $item]} { lappend inventory $item } }
    proc remove {item} { variable inventory; set index [lsearch -exact $inventory $item]; if {$index >= 0} { set inventory [lreplace $inventory $index $index] } }
    proc remember {} { variable undoStack; if {[llength $undoStack] >= 20} { set undoStack [lrange $undoStack 1 end] }; lappend undoStack [stateData] }

    proc title {} {
        variable room
        array set names {living "Living Room" kitchen "Kitchen" office "Home Office" balcony "Balcony"}
        return $names($room)
    }
    proc look {} {
        variable room; variable plantAwake; variable routerOnline; variable callLive; variable hintsUsed; variable moves
        say "\n== [title] =="
        switch -- $room {
            living { say "The video call is frozen. A houseplant wears the manager's headset. Doors lead to kitchen, office, and balcony." }
            kitchen { say "A mug says WORLD'S OKAYEST REMOTE WORKER. The kettle has seen things. Door: living." }
            office { say "A laptop displays 404: OUTSIDE NOT FOUND. A loose network cable lies beside it. Door: living." }
            balcony { if {$plantAwake} { say "The manager plant nods toward the office. Door: living." } else { say "The manager plant is thirsty and judging your meeting etiquette. Door: living." } }
        }
        if {$routerOnline} { say "The router light is reassuringly green." }
        if {$callLive} { say "Jordan's face is back on screen. The meeting survives." }
    }
    proc map {} {
        variable room
        say "APARTMENT MAP (you are in [title])"
        say "                 Balcony"
        say "                    |"
        say "Kitchen ---- Living Room ---- Home Office"
        array set connections {
            living "kitchen, office, balcony"
            kitchen "living room"
            office "living room"
            balcony "living room"
        }
        say "Connections from here: $connections($room)"
    }
    proc go {destination} {
        variable room; variable moves
        set destinations {living living kitchen kitchen office office balcony balcony}
        if {![dict exists $destinations $destination]} { say "You cannot go there from here. Try living, kitchen, office, or balcony."; return }
        if {$room ne "living" && $destination ne "living"} { say "Only the living room connects to that doorway."; return }
        remember; set room $destination; incr moves; look
    }
    proc take {item} {
        variable room; variable mugAvailable; variable cableAvailable; variable moves
        if {$item eq "mug" && $room eq "kitchen" && $mugAvailable} { remember; set mugAvailable 0; add mug; incr moves; say "Taken: mug. It hums with lukewarm purpose."; return }
        if {$item eq "cable" && $room eq "office" && $cableAvailable} { remember; set cableAvailable 0; add cable; incr moves; say "Taken: network cable. It has one job."; return }
        say "That item is not here. Look around, or stop trying to steal the walls."
    }
    proc use {item} {
        variable room; variable plantAwake; variable routerOnline; variable callLive; variable hintsUsed; variable moves
        if {![has $item]} { say "You are not carrying that."; return }
        if {$item eq "mug" && $room eq "balcony"} { remember; remove mug; set plantAwake 1; add leaf-key; incr moves; say "You water the manager plant. It hands you a leaf-shaped key and schedules a 1:1."; return }
        if {$item eq "leaf-key" && $room eq "office"} { remember; remove leaf-key; set routerOnline 1; incr moves; say "The leaf-key fits the router's tiny reset slot. The internet remembers you."; return }
        if {$item eq "cable" && $room eq "office" && $routerOnline} { remember; remove cable; set callLive 1; incr moves; say "Cable connected. The video call returns: 'You're still on mute.' You win in $moves moves, with $hintsUsed hint(s) used."; return }
        say "That combination does nothing useful yet."
    }
    proc inventory {} {
        variable inventory
        if {[llength $inventory] == 0} { say "Inventory: empty, like your calendar after 4pm." } else { say "Inventory: [join $inventory {, }]" }
    }
    proc recordCommand {words} {
        variable commandHistory
        set command [string tolower [lindex $words 0]]
        if {$command in {save load}} { set entry "$command PATH-REDACTED" } else { set entry [join $words " "] }
        if {[llength $commandHistory] >= 20} { set commandHistory [lrange $commandHistory 1 end] }
        lappend commandHistory $entry
        logCommand $entry
    }
    proc logCommand {entry} { variable transcriptChannel; if {$transcriptChannel ne ""} { puts $transcriptChannel "COMMAND: $entry"; flush $transcriptChannel } }
    proc history {action} {
        variable commandHistory
        if {$action eq "clear"} { set commandHistory {}; say "Command history cleared."; return }
        if {[llength $commandHistory] == 0} { say "Command history: empty."; return }
        say "COMMAND HISTORY (most recent last)"
        set number 1
        foreach entry $commandHistory { say "$number. $entry"; incr number }
    }
    proc examine {target} {
        variable room; variable plantAwake; variable routerOnline; variable callLive; variable mugAvailable; variable cableAvailable
        set target [string tolower $target]
        if {$target in {call video video-call}} {
            if {$room eq "living"} { if {$callLive} { say "Jordan's face is back on screen, no longer frozen. The meeting survives." } else { say "The frozen call shows Jordan mid-blink. The meeting is waiting for one small miracle." }; return }
        }
        if {$target in {plant houseplant manager}} {
            if {$room in {living balcony}} { if {$plantAwake} { say "The manager plant is alert, leafy, and taking notes." } else { say "The manager plant is wilted and judging your hydration choices." }; return }
        }
        if {$target in {mug cup}} {
            if {[has mug] || ($room eq "kitchen" && $mugAvailable)} { say "The mug reads WORLD'S OKAYEST REMOTE WORKER. It is sturdy enough for a small rescue mission."; return }
        }
        if {$target in {kettle}} { if {$room eq "kitchen"} { say "The kettle has seen things. It offers warmth, but no useful plan."; return } }
        if {$target in {laptop computer}} { if {$room eq "office"} { if {$callLive} { say "The laptop shows Jordan's live video call. It is still on mute, naturally." } else { say "The laptop insists: 404: OUTSIDE NOT FOUND. It is connected to hope by implication only." }; return } }
        if {$target in {cable network-cable}} {
            if {[has cable] || ($room eq "office" && $cableAvailable)} { say "The network cable has two ends and exactly one job: connect something."; return }
        }
        if {$target in {router modem}} {
            if {$room eq "office"} { if {$routerOnline} { say "The router light is green. It looks smug." } else { say "The router has a tiny reset slot and the expression of a device awaiting a precise key." }; return }
        }
        if {$target in {leaf-key key}} { if {[has leaf-key]} { say "The leaf-key is shaped like a plant leaf. It feels purpose-built, but refuses to explain itself."; return } }
        say "You cannot examine that here. Look around or examine something visible or carried."
    }
    proc journal {} {
        variable plantAwake; variable routerOnline; variable callLive; variable inventory; variable hintsUsed
        say "JOURNAL"
        say "Observed clues:"
        say "- The video call was frozen when you arrived."
        say "- The apartment has a kitchen, office, and balcony."
        if {[llength $inventory] > 0} { say "Carrying: [join $inventory {, }]" } else { say "Carrying: nothing" }
        say "Completed objectives:"
        set completed 0
        if {$plantAwake} { say "- Watered the manager plant."; incr completed }
        if {$routerOnline} { say "- Reset the router with the leaf-key."; incr completed }
        if {$callLive} { say "- Reconnected the video call."; incr completed }
        if {!$completed} { say "- None yet (the journal keeps its secrets)." }
        say "Hints used: $hintsUsed"
    }
    proc help {} { say "Commands: look | map | examine TARGET | go ROOM | take ITEM | use ITEM | inventory | journal | hint | undo | history | history clear | save PATH | load PATH | restart | quit" }
    proc stateData {} {
        variable room; variable inventory; variable plantAwake; variable routerOnline; variable callLive; variable mugAvailable; variable cableAvailable; variable hintDepth; variable hintsUsed; variable moves; variable hintStage
        set stage "mug"; if {$plantAwake} { set stage "router" }; if {$routerOnline} { set stage "cable" }
        set storedDepth $hintDepth; if {![info exists hintStage] || $hintStage ne $stage} { set storedDepth 0 }
        return [dict create schema 1 room $room inventory $inventory plantAwake $plantAwake routerOnline $routerOnline callLive $callLive mugAvailable $mugAvailable cableAvailable $cableAvailable hintDepth $storedDepth hintsUsed $hintsUsed moves $moves hintStage $stage]
    }
    proc validBool {value} { expr {[string is integer -strict $value] && ($value == 0 || $value == 1)} }
    proc validateState {data} {
        foreach key {schema room inventory plantAwake routerOnline callLive mugAvailable cableAvailable hintDepth hintsUsed moves hintStage} { if {[catch {dict get $data $key}]} { error "save is missing $key" } }
        if {[dict get $data schema] ne "1"} { error "unsupported save schema" }
        if {[lsearch -exact {living kitchen office balcony} [dict get $data room]] < 0} { error "save has an invalid room" }
        set items [dict get $data inventory]
        if {[llength $items] > 4} { error "save inventory is too large" }
        foreach item $items { if {[lsearch -exact {mug cable leaf-key} $item] < 0} { error "save has an invalid item" } }
        if {[llength [lsort -unique $items]] != [llength $items]} { error "save inventory has duplicates" }
        if {![validBool [dict get $data plantAwake]] || ![validBool [dict get $data routerOnline]] || ![validBool [dict get $data callLive]] || ![validBool [dict get $data mugAvailable]] || ![validBool [dict get $data cableAvailable]]} { error "save has an invalid flag" }
        foreach key {hintDepth hintsUsed moves} { set value [dict get $data $key]; if {![string is integer -strict $value] || $value < 0} { error "save has an invalid counter" } }
        if {[dict get $data hintDepth] > 2 || [dict get $data hintsUsed] > 100 || [dict get $data moves] > 10000} { error "save counters exceed limits" }
        if {[dict get $data plantAwake] && [lsearch -exact $items mug] >= 0} { error "save puzzle state is inconsistent" }
        if {[dict get $data routerOnline] && ![dict get $data plantAwake]} { error "save puzzle state is inconsistent" }
        if {[dict get $data routerOnline] && [lsearch -exact $items leaf-key] >= 0} { error "save puzzle state is inconsistent" }
        if {[dict get $data callLive] && ![dict get $data routerOnline]} { error "save puzzle state is inconsistent" }
        set stage "mug"; if {[dict get $data plantAwake]} { set stage "router" }; if {[dict get $data routerOnline]} { set stage "cable" }
        if {[dict get $data hintStage] ne $stage} { error "save hint stage is inconsistent" }
        if {[dict get $data hintStage] ni {mug router cable}} { error "save has an invalid hint stage" }
        if {[dict get $data plantAwake] && ![dict get $data routerOnline] && [lsearch -exact $items leaf-key] < 0} { error "save puzzle state is missing leaf-key" }
        if {[dict get $data mugAvailable] == 0 && [lsearch -exact $items mug] < 0 && ![dict get $data plantAwake]} { error "save puzzle state is missing mug" }
        if {[dict get $data cableAvailable] == 0 && [lsearch -exact $items cable] < 0 && ![dict get $data callLive]} { error "save puzzle state is missing cable" }
        if {[dict get $data mugAvailable] != (![dict get $data plantAwake] && [lsearch -exact $items mug] < 0)} { error "save mug availability is inconsistent" }
        if {[dict get $data cableAvailable] != (![dict get $data callLive] && [lsearch -exact $items cable] < 0)} { error "save cable availability is inconsistent" }
        if {([lsearch -exact $items leaf-key] >= 0) != ([dict get $data plantAwake] && ![dict get $data routerOnline])} { error "save leaf-key is inconsistent" }
        if {[dict get $data callLive] && [lsearch -exact $items cable] >= 0} { error "save retains a connected cable" }
        return 1
    }
    proc restoreState {data} {
        variable room; variable inventory; variable plantAwake; variable routerOnline; variable callLive; variable mugAvailable; variable cableAvailable; variable hintDepth; variable hintsUsed; variable moves; variable hintStage
        set room [dict get $data room]
        set inventory [dict get $data inventory]
        set plantAwake [dict get $data plantAwake]
        set routerOnline [dict get $data routerOnline]
        set callLive [dict get $data callLive]
        set mugAvailable [dict get $data mugAvailable]
        set cableAvailable [dict get $data cableAvailable]
        set hintDepth [dict get $data hintDepth]
        set hintsUsed [dict get $data hintsUsed]
        set moves [dict get $data moves]
        set hintStage [dict get $data hintStage]
    }
    proc undo {} {
        variable undoStack; variable hintsUsed
        if {[llength $undoStack] == 0} { say "Nothing to undo."; return }
        set preservedHints $hintsUsed
        set last [expr {[llength $undoStack] - 1}]
        set previous [lindex $undoStack $last]
        if {$last == 0} { set undoStack {} } else { set undoStack [lrange $undoStack 0 [expr {$last - 1}]] }
        restoreState $previous
        if {$hintsUsed < $preservedHints} { set hintsUsed $preservedHints }
        say "Undid last action."
        look
    }
    proc saveState {path} {
        if {$path eq ""} { error "save needs a path" }
        set temp "${path}.tmp-[pid]"
        set channel [open $temp {WRONLY CREAT EXCL}]
        if {[catch {puts -nonewline $channel [stateData]; close $channel; file rename -force $temp $path} error]} {
            catch {close $channel}; catch {file delete -force $temp}; error $error
        }
    }
    proc loadState {path} {
        if {$path eq ""} { error "load needs a path" }
        if {![file exists $path] || [file size $path] > 8192} { error "save is missing or too large" }
        set channel [open $path r]; set raw [read $channel 8192]; close $channel
        if {[catch {dict size $raw}]} { error "save is not a valid state dict" }
        validateState $raw
        restoreState $raw
        variable undoStack
        set undoStack {}
    }
    proc hint {} {
        variable hintDepth; variable hintsUsed; variable plantAwake; variable routerOnline; variable callLive
        if {$callLive} { say "No hint needed: the call is live."; return }
        set stage mug
        if {$plantAwake} { set stage router }
        if {$routerOnline} { set stage cable }
        if {![info exists ::Game::hintStage] || $::Game::hintStage ne $stage} { set ::Game::hintStage $stage; set hintDepth 0 }
        if {$hintDepth < 2} { incr hintDepth; incr hintsUsed }
        if {$stage eq "mug"} {
            if {$hintDepth == 1} { say "Hint: something in the kitchen could help the thirsty manager." } else { say "Hint: go kitchen, take mug, then bring it to the balcony." }
        } elseif {$stage eq "router"} {
            if {$hintDepth == 1} { say "Hint: the leaf-key has one oddly specific destination." } else { say "Hint: take the leaf-key to the office router." }
        } else {
            if {$hintDepth == 1} { say "Hint: the office cable is waiting for a green light." } else { say "Hint: use cable in the office now that the router is online." }
        }
    }

    proc handle {line} {
        set words [regexp -all -inline {\S+} [string trim $line]]
        set command [string tolower [lindex $words 0]]
        set argument [lindex $words 1]
        set normalizedArgument [string tolower $argument]
        set argumentCount [llength $words]
        if {$argumentCount == 0} { return 1 }
        if {$command ne "history"} { recordCommand $words } else { logCommand [join $words " "] }
        switch -- $command {
            look { if {$argumentCount != 1} { say "look takes no arguments." } else { look } }
            map { if {$argumentCount != 1} { say "map takes no arguments." } else { map } }
            examine { if {$argumentCount != 2} { say "examine takes one target." } else { examine $normalizedArgument } }
            go { if {$argumentCount != 2} { say "go takes one room." } else { go $normalizedArgument } }
            take { if {$argumentCount != 2} { say "take takes one item." } else { take $normalizedArgument } }
            use { if {$argumentCount != 2} { say "use takes one item." } else { use $normalizedArgument } }
            inventory { if {$argumentCount != 1} { say "inventory takes no arguments." } else { inventory } }
            journal { if {$argumentCount != 1} { say "journal takes no arguments." } else { journal } }
            history { if {$argumentCount == 1} { history list } elseif {$argumentCount == 2 && $normalizedArgument eq "clear"} { history clear } else { say "history takes no arguments, or: history clear" } }
            help { if {$argumentCount != 1} { say "help takes no arguments." } else { help; say "Hint gives two progressive nudges for the current puzzle step." } }
            hint { if {$argumentCount != 1} { say "hint takes no arguments." } else { hint } }
            undo { if {$argumentCount != 1} { say "undo takes no arguments." } else { undo } }
            save { if {$argumentCount != 2} { say "save takes one path." } else { if {[catch {saveState $argument} error]} { sayWithTranscript "Save error: $error" "Save error: operation failed (path redacted)" } else { say "Game saved." } } }
            load { if {$argumentCount != 2} { say "load takes one path." } else { if {[catch {loadState $argument} error]} { sayWithTranscript "Load error: $error" "Load error: operation failed (path redacted)" } else { say "Game loaded."; look } } }
            restart { reset; say "Fresh meeting, fresh hope."; look }
            quit - exit { return 0 }
            default { say "Unknown command. Type help for the tiny command list." }
        }
        return 1
    }
    proc run {{loadPath ""} {transcriptPath ""}} {
        variable commandHistory
        openTranscript $transcriptPath
        if {$loadPath eq ""} { reset } else { loadState $loadPath; set commandHistory {} }
        say "404: OUTSIDE NOT FOUND"; say "A 2020 terminal escape-room about reconnecting one video call."; help; look
        while {![eof stdin]} {
            puts -nonewline "> "; flush stdout
            if {[gets stdin line] < 0} { break }
            if {![handle $line]} { break }
        }
        say "Session closed. The plant remains manager."
        closeTranscript
    }
}

if {$argv0 eq [info script]} {
    set loadPath ""
    set transcriptPath ""
    set i 0
    while {$i < [llength $argv]} {
        set arg [lindex $argv $i]
        if {$arg eq "--help" || $arg eq "-h"} {
            puts "usage: game.tcl ?--help? ?--load PATH? ?--transcript PATH?"
            puts "Starts the 404 apartment escape room. --load resumes a validated save before accepting commands."
            puts "Interactive commands: look, map, examine TARGET, go ROOM, take ITEM, use ITEM, inventory, journal, hint, undo, history, history clear, save PATH, load PATH, restart, help, quit."
            exit 0
        } elseif {$arg eq "--load"} {
            incr i
            if {$i >= [llength $argv] || [lindex $argv $i] eq ""} { puts stderr "error: --load requires PATH"; exit 2 }
            set loadPath [lindex $argv $i]
        } elseif {$arg eq "--transcript"} {
            incr i
            if {$i >= [llength $argv] || [lindex $argv $i] eq ""} { puts stderr "error: --transcript requires PATH"; exit 2 }
            set transcriptPath [lindex $argv $i]
        } else {
            puts stderr "error: unknown option $arg"
            puts stderr "usage: game.tcl ?--help? ?--load PATH? ?--transcript PATH?"
            exit 2
        }
        incr i
    }
    if {[catch {Game::run $loadPath $transcriptPath} error]} { Game::closeTranscript; puts stderr "error: $error"; exit 2 }
}

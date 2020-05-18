#!/usr/bin/env tclsh

namespace eval Game {
    variable room living
    variable inventory {}
    variable plantAwake 0
    variable routerOnline 0
    variable callLive 0
    variable mugAvailable 1
    variable cableAvailable 1

    proc reset {} {
        variable room; variable inventory; variable plantAwake; variable routerOnline; variable callLive; variable mugAvailable; variable cableAvailable
        set room living; set inventory {}; set plantAwake 0; set routerOnline 0; set callLive 0; set mugAvailable 1; set cableAvailable 1
    }
    proc say {text} { puts $text }
    proc has {item} { variable inventory; expr {[lsearch -exact $inventory $item] >= 0} }
    proc add {item} { variable inventory; if {![has $item]} { lappend inventory $item } }
    proc remove {item} { variable inventory; set index [lsearch -exact $inventory $item]; if {$index >= 0} { set inventory [lreplace $inventory $index $index] } }

    proc title {} {
        variable room
        array set names {living "Living Room" kitchen "Kitchen" office "Home Office" balcony "Balcony"}
        return $names($room)
    }
    proc look {} {
        variable room; variable plantAwake; variable routerOnline; variable callLive
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
    proc go {destination} {
        variable room
        set destinations {living living kitchen kitchen office office balcony balcony}
        if {![dict exists $destinations $destination]} { say "You cannot go there from here. Try living, kitchen, office, or balcony."; return }
        if {$room ne "living" && $destination ne "living"} { say "Only the living room connects to that doorway."; return }
        set room $destination; look
    }
    proc take {item} {
        variable room; variable mugAvailable; variable cableAvailable
        if {$item eq "mug" && $room eq "kitchen" && $mugAvailable} { set mugAvailable 0; add mug; say "Taken: mug. It hums with lukewarm purpose."; return }
        if {$item eq "cable" && $room eq "office" && $cableAvailable} { set cableAvailable 0; add cable; say "Taken: network cable. It has one job."; return }
        say "That item is not here. Look around, or stop trying to steal the walls."
    }
    proc use {item} {
        variable room; variable plantAwake; variable routerOnline; variable callLive
        if {![has $item]} { say "You are not carrying that."; return }
        if {$item eq "mug" && $room eq "balcony"} { remove mug; set plantAwake 1; add leaf-key; say "You water the manager plant. It hands you a leaf-shaped key and schedules a 1:1."; return }
        if {$item eq "leaf-key" && $room eq "office"} { remove leaf-key; set routerOnline 1; say "The leaf-key fits the router's tiny reset slot. The internet remembers you."; return }
        if {$item eq "cable" && $room eq "office" && $routerOnline} { remove cable; set callLive 1; say "Cable connected. The video call returns: 'You're still on mute.' You win."; return }
        say "That combination does nothing useful yet."
    }
    proc inventory {} {
        variable inventory
        if {[llength $inventory] == 0} { say "Inventory: empty, like your calendar after 4pm." } else { say "Inventory: [join $inventory {, }]" }
    }
    proc help {} { say "Commands: look | go ROOM | take ITEM | use ITEM | inventory | restart | quit" }

    proc handle {line} {
        set words [regexp -all -inline {\S+} [string trim $line]]
        set command [string tolower [lindex $words 0]]
        set argument [string tolower [lindex $words 1]]
        set argumentCount [llength $words]
        if {$argumentCount == 0} { return 1 }
        switch -- $command {
            look { if {$argumentCount != 1} { say "look takes no arguments." } else { look } }
            go { if {$argumentCount != 2} { say "go takes one room." } else { go $argument } }
            take { if {$argumentCount != 2} { say "take takes one item." } else { take $argument } }
            use { if {$argumentCount != 2} { say "use takes one item." } else { use $argument } }
            inventory { if {$argumentCount != 1} { say "inventory takes no arguments." } else { inventory } }
            help { if {$argumentCount != 1} { say "help takes no arguments." } else { help } }
            restart { reset; say "Fresh meeting, fresh hope."; look }
            quit - exit { return 0 }
            default { say "Unknown command. Type help for the tiny command list." }
        }
        return 1
    }
    proc run {} {
        reset; say "404: OUTSIDE NOT FOUND"; say "A 2020 terminal escape-room about reconnecting one video call."; help; look
        while {![eof stdin]} {
            puts -nonewline "> "; flush stdout
            if {[gets stdin line] < 0} { break }
            if {![handle $line]} { break }
        }
        say "Session closed. The plant remains manager."
    }
}

if {$argv0 eq [info script]} { Game::run }

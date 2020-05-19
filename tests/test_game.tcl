#!/usr/bin/env tclsh
set root [file normalize [file join [file dirname [info script]] ..]]
set app [file join $root app game.tcl]
proc runGame {app commands} {
    set inputPath [file join [pwd] "test-input-[pid]-[clock clicks].txt"]
    set inputChannel [open $inputPath w]
    puts -nonewline $inputChannel $commands; close $inputChannel
    set code [catch {exec /usr/bin/tclsh $app < $inputPath} output options]
    file delete -force $inputPath
    if {$code} { return -options $options $output }
    return $output
}
proc assertContains {text needle label} {
    if {[string first $needle $text] < 0} { error "$label: missing <$needle>" }
}
set win [runGame $app "go kitchen\ntake mug\ngo living\ngo balcony\nuse mug\ngo living\ngo office\ntake cable\nuse leaf-key\nuse cable\nquit"]
assertContains $win "You win" winning-route
assertContains $win "Cable connected" winning-cable
set bad [runGame $app "take cable\nuse cable\nuse {puts HACKED}\nquit"]
assertContains $bad "not here" impossible-take
assertContains $bad "not carrying" wrong-item
if {[string first "HACKED" $bad] >= 0} { error "player text was executed" }
set parser [runGame $app "go    kitchen\ntake\tmug\ntake mug\nlook extra words\nuse {puts HACKED};\nquit"]
assertContains $parser "Taken: mug" whitespace-parser
assertContains $parser "not here" repeated-take
assertContains $parser "look takes no arguments" extra-arguments
assertContains $parser "use takes one item" injection-is-data
if {[string first "HACKED" $parser] >= 0} { error "parser executed injection text" }
set restart [runGame $app "go kitchen\ntake mug\nrestart\ninventory\nquit"]
assertContains $restart "Fresh meeting" restart-message
assertContains $restart "Inventory: empty" restart-clears-state
assertContains [runGame $app "go kitchen\ntake mug\nrestart\ngo kitchen\ntake mug\nquit"] "Taken: mug" restart-restores-items
set hints [runGame $app "hint\nhint\nhint\ngo kitchen\ntake mug\ngo living\ngo balcony\nuse mug\nhint\nrestart\nhint\nquit"]
assertContains $hints "something in the kitchen" first-hint
assertContains $hints "go kitchen, take mug" second-hint
assertContains $hints "leaf-key" stage-reset-hint
if {[string first "with 0 hint" $hints] >= 0} { error "hint counter did not increment" }
set victory [runGame $app "go kitchen\ntake mug\ngo living\ngo balcony\nuse mug\ngo living\ngo office\ntake cable\nuse leaf-key\nuse cable\nquit"]
assertContains $victory "You win in 10 moves, with 0 hint(s) used" victory-summary
set eof [runGame $app "look"]
assertContains $eof "Session closed" eof-closes
puts "Tcl escape-room checks passed"

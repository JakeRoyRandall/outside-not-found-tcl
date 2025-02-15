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
set examineFresh [runGame $app "examine call\nexamine video\nexamine mug\nexamine office\nquit"]
assertContains $examineFresh "frozen call shows Jordan" examine-current-call
assertContains $examineFresh "frozen call shows Jordan" examine-alias
assertContains $examineFresh "cannot examine that here" examine-unseen-item
set examineBad [runGame $app "examine\nexamine {puts HACKED}\nexamine router\nquit"]
assertContains $examineBad "examine takes one target" examine-malformed
assertContains $examineBad "cannot examine that here" examine-unknown
if {[string first "HACKED" $examineBad] >= 0} { error "examine target was evaluated" }
set examineContext [runGame $app "go kitchen\nexamine cup\ntake mug\nexamine mug\ngo living\ngo balcony\nexamine plant\nuse mug\nexamine plant\nquit"]
assertContains $examineContext "sturdy enough for a small rescue mission" examine-carried-item
assertContains $examineContext "wilted and judging" examine-thirsty-plant
assertContains $examineContext "alert, leafy" examine-awake-plant
set freshJournal [runGame $app "journal\nquit"]
assertContains $freshJournal "JOURNAL" journal-command
assertContains $freshJournal "None yet" journal-no-progress
if {[string first "leaf-key" $freshJournal] >= 0 || [string first "router" $freshJournal] >= 0 || [string first "cable" $freshJournal] >= 0} { error "fresh journal revealed an unseen solution" }
set progressJournal [runGame $app "go kitchen\ntake mug\ngo living\ngo balcony\nuse mug\njournal\nquit"]
assertContains $progressJournal "Watered the manager plant" journal-progress
assertContains $progressJournal "leaf-key" journal-inventory
set journalSave [file join [pwd] "test-journal-[pid].dat"]
set journalRoundtrip [runGame $app "go kitchen\ntake mug\ngo living\ngo balcony\nuse mug\nsave $journalSave\nrestart\nload $journalSave\njournal\nquit"]
assertContains $journalRoundtrip "Watered the manager plant" journal-save-load
file delete -force $journalSave
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
set wonExamine [runGame $app "go kitchen\ntake mug\ngo living\ngo balcony\nuse mug\ngo living\ngo office\ntake cable\nuse leaf-key\nuse cable\ngo living\nexamine call\ngo office\nexamine laptop\nquit"]
assertContains $wonExamine "no longer frozen" examine-live-call
assertContains $wonExamine "live video call" examine-live-laptop
set savePath [file join [pwd] "test-save-[pid].dat"]
set saved [runGame $app "go kitchen\ntake mug\nsave $savePath\nrestart\nload $savePath\ninventory\nquit"]
assertContains $saved "Game saved" save-success
assertContains $saved "Game loaded" load-success
assertContains $saved "Inventory: mug" partial-roundtrip
set finished [runGame $app "go kitchen\ntake mug\ngo living\ngo balcony\nuse mug\ngo living\ngo office\ntake cable\nuse leaf-key\nuse cable\nsave $savePath\nrestart\nload $savePath\nquit"]
assertContains $finished "You win in 10 moves" finish-roundtrip
file delete -force $savePath
set corruptPath [file join [pwd] "test-corrupt-[pid].dat"]
set corrupt [open $corruptPath w]; puts -nonewline $corrupt "puts HACKED"; close $corrupt
set rejected [runGame $app "go kitchen\ntake mug\nload $corruptPath\ninventory\nquit"]
assertContains $rejected "Load error" corrupt-rejected
assertContains $rejected "Inventory: mug" failed-load-preserves-state
if {[string first "HACKED" $rejected] >= 0} { error "save content was evaluated" }
file delete -force $corruptPath
set upperPath [file join [pwd] "Test-Save-[pid].DAT"]
set upper [runGame $app "go kitchen\ntake mug\nsave $upperPath\nrestart\nload $upperPath\ninventory\nquit"]
assertContains $upper "Inventory: mug" uppercase-path
file delete -force $upperPath
set stagePath [file join [pwd] "test-stage-[pid].dat"]
set staged [runGame $app "hint\ngo kitchen\ntake mug\ngo living\ngo balcony\nuse mug\nsave $stagePath\nrestart\nload $stagePath\nhint\nquit"]
assertContains $staged "leaf-key has one oddly specific destination" stage-transition-hint-resets
file delete -force $stagePath
set undoBasic [runGame $app "go kitchen\ntake mug\nundo\ninventory\nundo\nlook\nquit"]
assertContains $undoBasic "Undid last action." undo-basic-message
assertContains $undoBasic "Inventory: empty" undo-restores-inventory
assertContains $undoBasic "== Living Room ==" undo-restores-room
set undoPuzzle [runGame $app "go kitchen\ntake mug\ngo living\ngo balcony\nuse mug\nundo\ninventory\njournal\nquit"]
assertContains $undoPuzzle "Inventory: mug" undo-restores-puzzle-item
if {[string first "Watered the manager plant" $undoPuzzle] >= 0} { error "undo did not restore plant puzzle state" }
set undoMoves [runGame $app "go kitchen\ntake mug\ngo living\ngo balcony\nuse mug\ngo living\ngo office\ntake cable\nuse leaf-key\nuse cable\nundo\nuse cable\nquit"]
assertContains $undoMoves "You win in 10 moves" undo-restores-move-count
set undoInfo [runGame $app "journal\nhint\njournal\nlook\ninventory\nundo\nquit"]
assertContains $undoInfo "Nothing to undo." info-does-not-record-history
assertContains $undoInfo "Hints used: 1" hint-is-preserved
set undoRestart [runGame $app "go kitchen\nrestart\nundo\nquit"]
assertContains $undoRestart "Nothing to undo." restart-clears-history
set undoLoadPath [file join [pwd] "test-undo-load-[pid].dat"]
set undoLoad [runGame $app "go kitchen\ntake mug\nsave $undoLoadPath\ngo living\nload $undoLoadPath\nundo\nquit"]
assertContains $undoLoad "Game loaded" load-clears-history
assertContains $undoLoad "Nothing to undo." load-clears-history-result
file delete -force $undoLoadPath
set manyActions ""
for {set i 0} {$i < 21} {incr i} {
    if {$i % 2 == 0} { append manyActions "go kitchen\n" } else { append manyActions "go living\n" }
}
append manyActions [string repeat "undo\n" 21] "quit\n"
set undoCap [runGame $app $manyActions]
if {[regexp -all {Undid last action\.} $undoCap] != 20} { error "undo history was not capped at 20 entries" }
assertContains $undoCap "Nothing to undo." undo-cap-exhausted
set badPath [file join [pwd] "test-invalid-[pid].dat"]
set bad [open $badPath w]; puts -nonewline $bad "schema 1 room living inventory {mug mug} plantAwake 0 routerOnline 0 callLive 0 mugAvailable 1 cableAvailable 1 hintDepth 0 hintsUsed 0 moves 0 hintStage mug"; close $bad
set invalid [runGame $app "go kitchen\ntake mug\nload $badPath\ninventory\nquit"]
assertContains $invalid "Load error" invariant-rejected
assertContains $invalid "Inventory: mug" invariant-preserves-state
file delete -force $badPath
set hugePath [file join [pwd] "test-huge-[pid].dat"]
set huge [open $hugePath w]; puts -nonewline $huge [string repeat x 9000]; close $huge
set oversized [runGame $app "load $hugePath\nquit"]
assertContains $oversized "Load error" oversized-rejected
file delete -force $hugePath
set eof [runGame $app "look"]
assertContains $eof "Session closed" eof-closes
puts "Tcl escape-room checks passed"

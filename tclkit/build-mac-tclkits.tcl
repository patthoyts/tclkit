#!/usr/bin/env tclsh

# Build tclkit 8.4 and 8.5, for x11 and aqua
#
# Requires a working tclsh.
#
# Creates 4 temp dirs to do the actual builds in: k84x, k84a, k85x, and k85a.
# If all builds launch properly, those build dirs will be deleted again.  One
# trick to prevent deletion of build dirs is to create a tclkit-darwin-dummy
# file, because the test at the end only succeeds if there are exactly 4 exes.
# This can speed up repeated runs quite a bit, i.e. when tweaking this script.
#
# The final build results end up in files called tclkit-* and tclkit85-*.
#
# jcw, 2007-06-20

package require http

file mkdir k84x k84a k85x k85a

if {$tcl_platform(machine) eq "i386"} {
    set suffix x86
} else {
    set suffix ppc
}

proc build_one {dest} {
    if {![file exists genkit]} {
        exec ln -s ../k84x/genkit ../k84x/src ../k84x/tars .
    }
    exec tclsh genkit A >@stdout
    exec tclsh genkit B tcl >@stdout
    exec sh genkit B >@stdout
    catch { exec sh genkit D >@stdout } ;# Tk/X11 fails, but is ok for E build
    exec sh genkit E >@stdout
    set exe [glob tclkit*-*]
    if {[exec $exe << {puts [package require Itcl]}] ne "3.3"} {
        error "cannot load incrtcl"
    }
    file rename -force $exe ../$dest
}

cd k84x
unset -nocomplain env(TCLKIT_AQUA) env(KIT_VERSION)
if {![file exists genkit]} {
    set fd [open genkit w]
    set t [http::geturl http://www.equi4.com/pub/tk/tars/genkit -channel $fd]
    close $fd
}
build_one tclkit-darwin-$suffix

cd ../k84a
set env(TCLKIT_AQUA) 1
build_one tclkit-darwin-$suffix-aqua

cd ../k85a
set env(KIT_VERSION) 5
build_one tclkit85-darwin-$suffix-aqua

cd ../k85x
unset env(TCLKIT_AQUA)
build_one tclkit85-darwin-$suffix

cd ..
if {[llength [glob tclkit*-darwin-*]] == 4} {
    file delete -force k84x k84a k85x k85a
}

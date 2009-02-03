#!/bin/sh

# Copy the script libraries for wrapping up into the various kits

V=8.4

mkdir -p kit.vfs/lib kitsh.vfs/lib kitsh.vfs/bin 
mkdir -p kit-unix.vfs/lib kitsh-unix.vfs/lib

rsync -aC ../Dists/Tcl/library/. kitsh.vfs/lib/tcl$V
rm kitsh.vfs/lib/tcl$V/encoding/*

for i in ascii cp1252 iso8859-1 iso8859-2 macRoman
do
    rsync -a ../Dists/Tcl/library/encoding/$i.enc kitsh.vfs/lib/tcl$V/encoding
done

rm -r kitsh.vfs/lib/tcl$V/dde*
rm -r kitsh.vfs/lib/tcl$V/reg*
rm -r kitsh.vfs/lib/tcl$V/http1.0 # the 2.x version is in http/
#rm -r kitsh.vfs/lib/tcl$V/tcltest*

rsync -aC ../Dists/Tk/library/. kit.vfs/lib/tk$V

FILES=`find kit.vfs/lib -type f -name license.terms -print`
test -n "$FILES" && rm $FILES
rm -r kit.vfs/lib/tk$V/demos
rm -r kit.vfs/lib/tk$V/images


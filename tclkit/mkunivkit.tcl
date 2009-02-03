#!/usr/bin/env tclsh

# take 2 mac tclkits and turn them into a universal binary
# adapted from a script by Mark Roseman
# jcw, 2007-06-18

if {[llength $argv] != 3} {
   puts stderr "usage: $argv0 ppcexe x86exe dest"
   exit -1
}

eval file delete -force tmp0 tmp1 tmp2 [glob -nocomplain {tmp[012].*}]

file copy [lindex $argv 0] tmp0
file copy [lindex $argv 1] tmp1

exec sdx unwrap tmp0
exec sdx mksplit tmp0

exec sdx unwrap tmp1
exec sdx mksplit tmp1

exec rsync -a tmp0.vfs/ tmp2.vfs
exec rsync -a tmp1.vfs/ tmp2.vfs

exec lipo -create tmp0.head tmp1.head -output tmp2

foreach x {itcl3.3/libitcl3.3.dylib tk8.4/libtk8.4.dylib tk8.5/libtk8.5.dylib} {
    if {[file exists tmp0.vfs/lib/$x]} {
        exec lipo -create tmp0.vfs/lib/$x tmp1.vfs/lib/$x \
                    -output tmp2.vfs/lib/$x
    }
}

exec sdx wrap [lindex $argv 2] -runtime tmp2 -vfs tmp2.vfs

eval file delete -force tmp0 tmp1 tmp2 [glob {tmp[012].*}]

# Copyright (C) 2000-2001 Jean-Claude Wippler <jcw@equi4.com>
#
# Updater for the MK-at-end-of-exe datafile (using VFS directory trees)
#
#   This code creates a new TclKit executable with a datafile at the end
#
#   This file is called "setup.tcl", because a freshly compiled TclKit
#   expects to find that in the current dir when it has no datafile yet.
#
#   Output is sent to file "log.txt", because there may not be a stdout.
#
# How to prepare a freshly compiled TclKit(Sh) for use:
#   1)  copy the exe as "kit.exe" into this dir (can be upx-compressed)
#   2)  make sure this script (setup.tcl) and "sync.tcl" are present
#   3)  put all files to be packaged in dirs "kitsh.vfs" and "kit.vfs"
#   4)  puts platform-specific files in dirs "kit[sh]-*.vfs"
#   5)  launch "./kit", the result will be called "tclkit"
# For tclkitsh: follow the same steps, but it'll only use "kitsh.vfs".

set compressed 1

proc history {args} {}

set origExe [info nameofexecutable]                 ;# e.g. "C:/.../kit.exe"
set origTail [file tail $origExe]                   ;# e.g. "kit.exe"
set origBase [file rootname $origTail]              ;# e.g. "kit"

set fromDir $origBase.vfs                           ;# e.g. "kit.vfs"
set platDir $origBase-$tcl_platform(platform).vfs   ;# e.g. "kit-unix.vfs"
set destExe "tcl[string tolower $origTail]"         ;# e.g. "tclkit.exe"

set LOG [open log.txt w]
proc tclLog {args} {puts $::LOG [join $args]; flush $::LOG}

# mount datafile, synchronize directory trees into it, and clean up

if {[catch {
  tclLog " creating $destExe from $origExe"
  file copy -force $origExe $destExe

  tclLog "loading static packages"
  catch {load "" vfs}

  tclLog "sourcing vfs code"
  source kitsh.vfs/lib/vfs/vfsUtils.tcl
  source kitsh.vfs/lib/vfs/vfslib.tcl
  source kitsh.vfs/lib/vfs/mk4vfs.tcl

  # the -nocommit flag merely prevents intermediate flushes, i.e.
  # if a file was written, then the close will still autocommit
  #
  # this means the datafile will be committed exactly once, which is
  # crucial to enable restoring custom tclkits to the original state

  tclLog "mounting destination filesystem"
  set m [vfs::mk4::Mount $destExe $destExe -nocommit]
  
  set dirs [list $fromDir $platDir]
  if {[string equal -nocase $fromDir kit.vfs]} {
    lappend dirs kitsh.vfs kitsh-$tcl_platform(platform).vfs
  }

  foreach dir $dirs {
    if {![file isdir $dir]} continue ;# silently skip if not present
    puts -nonewline "$dir: "
    set argv [list -compress $compressed -verbose 1 \
		      -auto 0 -noerror 0 -text 1 $dir $destExe]
    source sync.tcl
  }
  
  mk::file commit $m
  vfs::unmount $destExe
  
  set oSize [file size $origExe]
  set nSize [file size $destExe]

  tclLog " $origExe: $oSize, $destExe: $nSize"

# bump VFS config version by 0.001
  set configfile kitsh.vfs/config.tcl

  set fd [open $configfile]
  set v [lindex [gets $fd] 2]
  close $fd

  set v [expr {$v + 0.001}]
  # avoid .010, .020, etc - make sure we use all 3 digits
  if {int($v * 1000 + 0.5) % 10 == 0} {
    set v [expr {$v + 0.001}]
  }
  tclLog "next ::vfs::tclkit_version will be: $v"

  set fd [open $configfile w]
  puts $fd "set ::vfs::tclkit_version $v"
  close $fd
  
} err]} {
  tclLog "There was an error $err"
  tclLog "$::errorInfo"
}

exit ;# prevent further initialization

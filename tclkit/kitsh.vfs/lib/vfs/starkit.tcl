# Starkit support, see http://www.equi4.com/starkit/
# by Jean-Claude Wippler, July 2002

package provide starkit 1.2

# Starkit scripts can launched in a number of ways:
#   - wrapped or unwrapped
#   - using tclkit, or from tclsh/wish with a couple of pkgs installed
#   - with real MetaKit support, or with a read-only fake (ReadKit)
#   - as 2-file starkit deployment, or as 1-file starpack
#
# Furthermore, there are three variations:
#   current:  starkits
#   older:    VFS-based "scripted documents"
#   oldest:   pre-VFS "scripted documents"
#
# The code in here is only called directly from the current starkits.

# lassign is used so widely by now, make sure it is always available
if {![info exists auto_index(lassign)] && [info commands lassign] eq ""} {
    set auto_index(lassign) {
	proc lassign {l args} {
	    foreach v $l a $args { uplevel 1 [list set $a $v] }
	}
    }
}

namespace eval starkit {
    # called from the header of a starkit
    proc header {driver args} {
	if {[catch {
	    set self [info script]

	    package require ${driver}vfs
	    eval [list ::vfs::${driver}::Mount $self $self] $args

	    uplevel [list source [file join $self main.tcl]]
	}]} {
	    panic $::errorInfo
	}
    }

    # called from the startup script of a starkit to init topdir and auto_path
    # returns how the script was launched: starkit, starpack, unwrapped, or
    # sourced (2003: also tclhttpd, plugin, or service)
    proc startup {} {
	global argv0

	# 2003/02/11: new behavior, if starkit::topdir exists, don't disturb it
	if {![info exists starkit::topdir]} {
	  variable topdir ;# the root directory (while the starkit is mounted)
	}

	set script [file normalize [info script]]
	set topdir [file dirname $script]

	if {$topdir eq [info nameofexe]} { return starpack }

	# pkgs live in the $topdir/lib/ directory
	set lib [file join $topdir lib]
	if {[file isdir $lib]} { autoextend $lib }

	set a0 [file normalize $argv0]
	if {$topdir eq $a0} { return starkit }
	if {$script eq $a0} { return unwrapped }

	# detect when sourced from tclhttpd
	if {[info procs ::Httpd_Server] ne ""} { return tclhttpd }

	# detect when sourced from the plugin (tentative)
	if {[info exists ::embed_args]} { return plugin }

	# detect when run as an NT service
	if {[info exists ::tcl_service]} { return service }

	return sourced
    }

    # append an entry to auto_path if it's not yet listed
    proc autoextend {dir} {
	global auto_path
	set dir [file normalize $dir]
	if {[lsearch $auto_path $dir] < 0} {
	    lappend auto_path $dir
	}
    }

    # remount a starkit with different options
    proc remount {args} {
	variable topdir
	lassign [vfs::filesystem info $topdir] drv arg
	vfs::unmount $topdir
	
	eval [list [regsub handler $drv Mount] $topdir $topdir] $args
    }

    # terminate with an error message, using most appropriate mechanism
    proc panic {msg} {
	if {[info commands wm] ne ""} {
	    catch { wm withdraw . }
	    tk_messageBox -icon error -message $msg -title "Fatal error"
	} elseif {[info commands ::eventlog] ne ""} {
	    eventlog error $msg
	} else {
	    puts stderr $msg
	}
	exit
    }
}

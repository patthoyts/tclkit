package ifneeded Tk 8.4 [format {
  # this logic avoids catching an inappropriate load request
  if {[lsearch -exact [info loaded] {{} Tk}] >= 0} {
    load "" Tk
  } else {
    load %s Tk
  }
} [list [file join $dir libtk8.4[info sharedlibext]]]]

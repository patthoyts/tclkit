# the following lines fix vfs to init properly in slave interpreters
# thx B Theado, starkit mailing list, 2003-10-02
proc loadvfs dir {
  load {} vfs
  source [file join $dir vfsUtils.tcl]
  source [file join $dir vfslib.tcl]
}
package ifneeded vfs 1.2 [list loadvfs $dir]

package ifneeded scripdoc  1.0   [list source [file join $dir scripdoc.tcl]]
package ifneeded starkit   1.3.1 [list source [file join $dir starkit.tcl]]
package ifneeded vfslib    1.3.1 [list source [file join $dir vfslib.tcl]]
package ifneeded vfs::mk4  1.10  [list source [file join $dir mk4vfs.tcl]]
package ifneeded vfs::mkcl 1.2   [list source [file join $dir mkclvfs.tcl]]
package ifneeded vfs::zip  1.0   [list source [file join $dir zipvfs.tcl]]

# Old
package ifneeded mk4vfs 1.10 { package require vfs::mk4 }
package ifneeded zipvfs 1.0 { package require vfs::zip }

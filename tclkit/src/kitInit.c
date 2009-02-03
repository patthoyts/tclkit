/* 
 * tclAppInit.c --
 *
 *  Provides a default version of the main program and Tcl_AppInit
 *  procedure for Tcl applications (without Tk).  Note that this
 *  program must be built in Win32 console mode to work properly.
 *
 * Copyright (c) 1996-1997 by Sun Microsystems, Inc.
 * Copyright (c) 1998-1999 by Scriptics Corporation.
 * Copyright (c) 2000-2002 Jean-Claude Wippler <jcw@equi4.com>
 *
 * See the file "license.terms" for information on usage and redistribution
 * of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 * RCS: @(#) $Id$
 */

#ifdef KIT_INCLUDES_TK
#include <tk.h>
#else
#include <tcl.h>
#endif

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#undef WIN32_LEAN_AND_MEAN
#endif

#ifndef MB_TASKMODAL
#define MB_TASKMODAL 0
#endif

#include "tclInt.h"

#ifdef KIT_INCLUDES_ITCL
Tcl_AppInitProc	Itcl_Init;
#endif
Tcl_AppInitProc	Mk4tcl_Init, Vfs_Init, Rechan_Init, Zlib_Init;
#if 10 * TCL_MAJOR_VERSION + TCL_MINOR_VERSION < 85
Tcl_AppInitProc	Pwb_Init;
#endif
#ifdef TCL_THREADS
Tcl_AppInitProc	Thread_Init;
#endif
#ifdef _WIN32
Tcl_AppInitProc	Dde_Init, Registry_Init;
#endif

char *tclExecutableName;

    /*
     *  Attempt to load a "boot.tcl" entry from the embedded MetaKit file.
     *  If there isn't one, try to open a regular "setup.tcl" file instead.
     *  If that fails, this code will throw an error, using a message box.
     */

static char *preInitCmd = 
#ifdef _WIN32_WCE
/* silly hack to get wince port to launch, some sort of std{in,out,err} problem */
"open /kitout.txt a; open /kitout.txt a; open /kitout.txt a\n"
/* this too seems to be needed on wince - it appears to be related to the above */
"catch {rename source ::tcl::source}\n"
"proc source file {\n"
    "set old [info script]\n"
    "info script $file\n"
    "set fid [open $file]\n"
    "set data [read $fid]\n"
    "close $fid\n"
    "set code [catch {uplevel 1 $data} res]\n"
    "info script $old\n"
    "if {$code == 2} { set code 0 }\n"
    "return -code $code $res\n"
"}\n"
#endif
"proc tclKitInit {} {\n"
    "rename tclKitInit {}\n"
    "load {} Mk4tcl\n"
    "mk::file open exe [info nameofexecutable] -readonly\n"
    "set n [mk::select exe.dirs!0.files name boot.tcl]\n"
    "if {$n != \"\"} {\n"
        "set s [mk::get exe.dirs!0.files!$n contents]\n"
	"if {![string length $s]} { error \"empty boot.tcl\" }\n"
        "catch {load {} zlib}\n"
        "if {[mk::get exe.dirs!0.files!$n size] != [string length $s]} {\n"
	    "set s [zlib decompress $s]\n"
	"}\n"
    "} else {\n"
        "set f [open setup.tcl]\n"
        "set s [read $f]\n"
        "close $f\n"
    "}\n"
    "uplevel #0 $s\n"
#ifdef _WIN32
    "package ifneeded dde 1.3.1 {load {} dde}\n"
    "package ifneeded registry 1.1.5 {load {} registry}\n"
#endif
"}\n"
"tclKitInit"
;

static const char initScript[] =
"if {[file isfile [file join [info nameofexe] main.tcl]]} {\n"
    "if {[info commands console] != {}} { console hide }\n"
    "set tcl_interactive 0\n"
    "incr argc\n"
    "set argv [linsert $argv 0 $argv0]\n"
    "set argv0 [file join [info nameofexe] main.tcl]\n"
"} else continue\n"
;

/* SetExecName --

   Hack to get around Tcl bug 1224888.
*/

void SetExecName(Tcl_Interp *interp) {
    if (tclExecutableName == NULL) {
	int len = 0;
	Tcl_Obj *execNameObj;
	Tcl_Obj *lobjv[1];

	lobjv[0] = Tcl_GetVar2Ex(interp, "argv0", NULL, TCL_GLOBAL_ONLY);
	execNameObj = Tcl_FSJoinToPath(Tcl_FSGetCwd(interp), 1, lobjv);

	tclExecutableName = strdup(Tcl_GetStringFromObj(execNameObj, &len));
    }
}

int 
TclKit_AppInit(Tcl_Interp *interp)
{
#ifdef KIT_INCLUDES_ITCL
    Tcl_StaticPackage(0, "Itcl", Itcl_Init, NULL);
#endif 
    Tcl_StaticPackage(0, "Mk4tcl", Mk4tcl_Init, NULL);
#if 10 * TCL_MAJOR_VERSION + TCL_MINOR_VERSION < 85
    Tcl_StaticPackage(0, "pwb", Pwb_Init, NULL);
#endif 
    Tcl_StaticPackage(0, "rechan", Rechan_Init, NULL);
    Tcl_StaticPackage(0, "vfs", Vfs_Init, NULL);
    Tcl_StaticPackage(0, "zlib", Zlib_Init, NULL);
#ifdef TCL_THREADS
    Tcl_StaticPackage(0, "Thread", Thread_Init, NULL);
#endif
#ifdef _WIN32
    Tcl_StaticPackage(0, "dde", Dde_Init, NULL);
    Tcl_StaticPackage(0, "registry", Registry_Init, NULL);
#endif
#ifdef KIT_INCLUDES_TK
    Tcl_StaticPackage(0, "Tk", Tk_Init, Tk_SafeInit);
#endif

    /* the tcl_rcFileName variable only exists in the initial interpreter */
#ifdef _WIN32
    Tcl_SetVar(interp, "tcl_rcFileName", "~/tclkitrc.tcl", TCL_GLOBAL_ONLY);
#else
    Tcl_SetVar(interp, "tcl_rcFileName", "~/.tclkitrc", TCL_GLOBAL_ONLY);
#endif

    /* Hack to get around Tcl bug 1224888.  This must be run here and
     * in LibraryPathObjCmd because this information is needed both
     * before and after that command is run. */
    SetExecName(interp);

    TclSetPreInitScript(preInitCmd);
    if (Tcl_Init(interp) == TCL_ERROR)
        goto error;

#ifdef KIT_INCLUDES_TK
#ifdef _WIN32
    if (Tk_Init(interp) == TCL_ERROR)
        goto error;
    if (Tk_CreateConsoleWindow(interp) == TCL_ERROR)
        goto error;
#endif
#endif

      /* messy because TclSetStartupScriptPath is called slightly too late */
    if (Tcl_Eval(interp, initScript) == TCL_OK) {
        Tcl_Obj* path = TclGetStartupScriptPath();
	TclSetStartupScriptPath(Tcl_GetObjResult(interp));
	if (path == NULL)
	  Tcl_Eval(interp, "incr argc -1; set argv [lrange $argv 1 end]");
    }

    Tcl_SetVar(interp, "errorInfo", "", TCL_GLOBAL_ONLY);
    Tcl_ResetResult(interp);
    return TCL_OK;

error:
#ifdef KIT_INCLUDES_TK
#ifdef _WIN32
    MessageBeep(MB_ICONEXCLAMATION);
#ifndef _WIN32_WCE
    MessageBox(NULL, Tcl_GetStringResult(interp), "Error in TclKit",
        MB_ICONSTOP | MB_OK | MB_TASKMODAL | MB_SETFOREGROUND);
    ExitProcess(1);
#endif
    /* we won't reach this, but we need the return */
#endif
#endif
    return TCL_ERROR;
}

#!/bin/sh

# Build TclKit on Linux

V=8.4

P=`pwd`
O=$P/../Dists

cd $O/Tcl/unix
./configure --disable-shared --enable-symbols
make libtcl${V}g.a

cd $O/Tk/unix
./configure --disable-shared --with-tcl=$O/Tcl/unix --enable-symbols
make libtk${V}g.a

cd $O/Itcl/itcl
./configure --disable-shared --with-tcl=$O/Tcl/unix --enable-symbols
make libitcl3.3g.a

cd $O/Mk4tcl/builds
../unix/configure --disable-shared --with-tcl=$O/Tcl/generic --enable-symbols
make libmk4tcl.la

cd $P
pwd

W="-D_LARGEFILE64_SOURCE -DHAVE_STRUCT_STAT64=1 -DHAVE_TYPE_OFF64_T=1"
D="-DKIT_INCLUDES_TK $W"
A="-DTCL_LOCAL_APPINIT=TclKit_AppInit"
I="-I. -I$O/Tcl/generic -I$O/Tk/generic -I$O/Mk4tcl/include -I$O/Zlib"
L="-L$O/Zlib $O/Tcl/unix/libtcl${V}g.a $O/Tk/unix/libtk${V}g.a 
	$O/Itcl/itcl/libitcl3.3g.a $O/Mk4tcl/builds/.libs/libmk4tcl.a"
X="/usr/X11R6/lib/libX11.a"

rm -f *.o
gcc -c -g $I $D $TCL_DEFS src/*.c $O/Vfs/generic/vfs.c
gcc -c -g $I $D $TCL_DEFS $A $O/Tcl/unix/tclAppInit.c

g++ -o kit *.o $L $X -ldl -lieee -lm -lz
rm *.o

rm -f tclkit
./kit

mv tclkit tclkitg
mv kit kitg

ls -l tclkitg

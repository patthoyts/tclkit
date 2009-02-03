#!/bin/sh

# Build TclKit on Linux

V=8.4

P=`pwd`
O=$P/../Dists

cd $O/Tcl/unix
./configure --disable-shared
make libtcl$V.a

cd $O/Tk/unix
./configure --disable-shared --with-tcl=$O/Tcl/unix
make libtk$V.a

cd $O/Itcl/itcl
./configure --disable-shared --with-tcl=$O/Tcl/unix
make libitcl3.3.a

cd $O/Mk4tcl/builds
../unix/configure --disable-shared --with-tcl=$O/Tcl/generic
make libmk4tcl.la

cd $P
pwd

W="-D_LARGEFILE64_SOURCE -DHAVE_STRUCT_STAT64=1 -DHAVE_TYPE_OFF64_T=1"
D="-DNDEBUG -DKIT_INCLUDES_TK -DKIT_INCLUDES_ITCL $W"
A="-DTCL_LOCAL_APPINIT=TclKit_AppInit"
I="-I. -I$O/Tcl/generic -I$O/Tk/generic -I$O/Mk4tcl/include"
L="$O/Tcl/unix/libtcl$V.a $O/Tk/unix/libtk$V.a \
	$O/Itcl/itcl/libitcl3.3.a $O/Mk4tcl/builds/.libs/libmk4tcl.a"
#X="/usr/X11R6/lib/libX11.a"
X="-L/usr/X11R6/lib -lX11"

rm -f *.o
gcc -c -O3 $I $D $TCL_DEFS src/*.c $O/Vfs/generic/vfs.c
gcc -c -O3 $I $D $TCL_DEFS $A $O/Tcl/unix/tclAppInit.c
g++ -static -o kit *.o $L $X -ldl -lieee -lm -lz

strip kit
rm *.o

rm -f tclkit
./kit

ls -l tclkit

@echo off

echo Building kitsh.exe and kit.exe with MSVC6 ...

del kitsh.exe
del kit.exe

call c:\progra~1\micros~1\vc98\bin\vcvars32.bat

msdev msvc6\kit.dsw /make "tclkitsh - Win32 Release" "tclkit - Win32 Release"

goto done

del tclkitsh.exe
kitsh
del full\tclkitsh.exe
move tclkitsh.exe full\tclkitsh.exe

upx -q -9 kitsh.exe
kitsh

del tclkit.exe
kit
del full\tclkit.exe
move tclkit.exe full\tclkit.exe

upx -q -9 kit.exe
del tclkit.exe
start /w kit

dir tclkit*.exe

: done

REM Build tclkitsh.exe and tclkit.exe with MSVC6

call msvc.bat

upx -q -9 kitsh.exe
del tclkitsh.exe
kitsh

upx -q -9 kit.exe
del tclkit.exe
start /w kit

dir tclkit*.exe

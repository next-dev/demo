@echo off
call m.bat
if not errorlevel 1 (
    bin\hdfmonkey put \sdcard\cspect-next-2gb.img demo.nex
    bin\CSpect.exe -brk -s14 -w3 -zxnext -nextrom -map=demo.nex.map -mmc=\sdcard\cspect-next-2gb.img
)

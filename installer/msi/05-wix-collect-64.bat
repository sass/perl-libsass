@echo off
SETLOCAL
call ..\settings.cmd

if not exist 64 mkdir 64

cd 64

"%WIX%\bin\heat.exe" dir "." -nologo -cg gm -nologo -gg -scom -sreg -ke -dr APPLICATIONFOLDER -template fragment -out dist\bin.wxs -platform x86

cd ..
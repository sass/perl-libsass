@echo off
SETLOCAL
call ..\settings.cmd

if not exist 64 mkdir 64

cd 64

call copy ..\..\exe\64\psass.exe psass.exe

cd ..

@echo off
SETLOCAL
call ..\settings.cmd

if not exist 32 mkdir 32

cd 32

call copy ..\..\exe\32\psass.exe psass.exe

cd ..

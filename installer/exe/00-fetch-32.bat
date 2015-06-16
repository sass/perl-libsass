@echo off
SETLOCAL
call ..\settings.cmd

if not exist 32 mkdir 32

cd 32

..\..\files\utils\wget -c "http://webmerge.ocbnet.ch/portable/webmerge-perl-x32.exe"

webmerge-perl-x32.exe -y

cd ..
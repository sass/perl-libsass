@echo off
SETLOCAL
call ..\settings.cmd

call ..\settings.cmd

SET PERLPATH=%CD%\64\perl
SET PATH=C:\Windows\system32

SET PATH=%PERLPATH%\perl\site\bin;%PATH%
SET PATH=%PERLPATH%\perl\bin;%PATH%
SET PATH=%PERLPATH%\c\bin;%PATH%

cd 64

call pp -B -o psass.exe ^
-I ../../../blib/lib ^
-M Encode::Byte ^
-M Win32::ChangeNotify ^
-M Filesys::Notify::Simple ^
../../../bin/psass.pl

REM tested and working, but much bigger size
REM -l "%PERLPATH%/c/bin/_libsass-0.dll" ^

cd ..

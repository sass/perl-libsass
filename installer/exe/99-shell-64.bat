@echo off
SETLOCAL
call ..\settings.cmd

SET PERLPATH=%CD%\64\perl
SET PATH=C:\Windows\system32

SET PATH=%PERLPATH%\perl\site\bin;%PATH%
SET PATH=%PERLPATH%\perl\bin;%PATH%
SET PATH=%PERLPATH%\c\bin;%PATH%

cd 64

cmd

cd ..

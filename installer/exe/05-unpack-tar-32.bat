@echo off
SETLOCAL
call ..\settings.cmd

if exist dist\32 rd /S dist\32
if not exist dist mkdir dist
if not exist dist\32 mkdir dist\32

SET PERLPATH=%CD%\32\perl
SET PATH=C:\Windows\system32

SET PATH=%PERLPATH%\perl\site\bin;%PATH%
SET PATH=%PERLPATH%\perl\bin;%PATH%
SET PATH=%PERLPATH%\c\bin;%PATH%

cd dist\32

call ptar -x -v -z -vf ..\..\..\..\CSS-Sass-v%RELVERSION%.tar.gz

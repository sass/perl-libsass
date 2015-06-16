@echo off
SETLOCAL
call ..\settings.cmd

if exist dist\64 rd /S dist\64
if not exist dist mkdir dist
if not exist dist\64 mkdir dist\64

SET PERLPATH=%CD%\64\perl
SET PATH=C:\Windows\system32

SET PATH=%PERLPATH%\perl\site\bin;%PATH%
SET PATH=%PERLPATH%\perl\bin;%PATH%
SET PATH=%PERLPATH%\c\bin;%PATH%

cd dist\64

call ptar -x -v -z -vf ..\..\..\..\CSS-Sass-v%RELVERSION%.tar.gz

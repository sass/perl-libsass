@echo off
SETLOCAL
call ..\settings.cmd

pushd ..\..

perl Build.PL
call build versionize %RELVERSION%

perl Build.PL
call Build dist

popd

pause
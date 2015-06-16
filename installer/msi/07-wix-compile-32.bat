@echo off
SETLOCAL
call ..\settings.cmd

git describe --tags --abbrev=0 > git-tag.txt
SET /p gitversion=<git-tag.txt
del git-tag.txt

call set gitversion=%%RELVERSION:v=%%

cd 32

"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -dGitVersion=%gitversion% -out dist\bin.wixobj dist\bin.wxs

"%WIX%\bin\candle.exe" -arch x86 -dPlatform="x86" -nologo -ext WixBalExtension -ext WixUtilExtension -dGitVersion=%gitversion% -out dist\psass.wixobj ..\res\psass.wxs

cd ..

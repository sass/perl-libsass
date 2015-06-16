@echo off
SETLOCAL
call ..\settings.cmd

cd res
cd RefreshEnvAction

if exist "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" (
	echo found visual studio [express] 2012 in standard path
	call "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x86
	set PlatformToolset=v120
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" (
	echo found visual studio [express] 2011 in standard path
	call "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x86
	set PlatformToolset=v110
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" (
	echo found visual studio [express] 2010 in standard path
	call "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC\vcvarsall.bat" x86
	set PlatformToolset=v100
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcvarsall.bat" (
	echo found visual studio [express] 2008 in standard path
	call "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC\vcvarsall.bat" x86
	set PlatformToolset=v90
) else (
	goto errorCompiler
)

:build

msbuild /p:Configuration=debug /p:PlatformToolset=%PlatformToolset%
msbuild /p:Configuration=release /p:PlatformToolset=%PlatformToolset%

if exist "bin\release\RefreshEnv.dll" (
	copy "bin\release\RefreshEnv.dll" ..\
) else (
	goto errorCompile
)

goto end

:errorCompile

echo seems like compilation was not successfull, aborting

goto end

:errorCompiler

echo no compiler found, please install vistual studio express (2011 preferred)

goto end

:end

cd ..
cd ..

@echo off
SETLOCAL
call ..\settings.cmd

SET PERLPATH=%CD%\32\perl
SET PATH=C:\Windows\system32

SET PATH=%PERLPATH%\perl\site\bin;%PATH%
SET PATH=%PERLPATH%\perl\bin;%PATH%
SET PATH=%PERLPATH%\c\bin;%PATH%

SET PERL_DIR=%CD%\32\perl\perl
REM you will need to copy this over from data/.cpanm
SET PAR_PACKER_SRC=%CD%\32\perl\cpan\build

REM for /D %%a in (32\perl\data\.cpanm\work) do @if exist %%a echo %%a
for /f "tokens=*" %%a in ('dir /b /a:d "32\perl\data\.cpanm\work"') do @if exist 32\perl\data\.cpanm\work\%%a\PAR-Packer-* set workpath=%%a
for /f "tokens=*" %%a in ('dir /b /a:d "32\perl\data\.cpanm\work\%workpath%\PAR-Packer-*"') do set workversion=%%a

echo "got %workpath% - %workversion%"

mkdir 32\perl\cpan\build

xcopy /S /E /Q /Y "32\perl\data\.cpanm\work\%workpath%\%workversion%" "32\perl\cpan\build\%workversion%\"

copy /Y res\psass.ico "%PAR_PACKER_SRC%\%workversion%\myldr\winres\pp.ico"

pushd "%PAR_PACKER_SRC%\%workversion%\myldr\"

del ppresource.coff
perl Makefile.PL
dmake boot.exe
dmake Static.pm

popd

attrib -R "%PERL_DIR%\site\lib\PAR\StrippedPARL\Static.pm"
copy /Y "%PAR_PACKER_SRC%\%workversion%\myldr\Static.pm" "%PERL_DIR%\site\lib\PAR\StrippedPARL\Static.pm"

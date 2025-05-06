@echo off

:: --- May need to be modified ---

:: For both strings, version number at the end may be different for you.
:: VS 2017 or VS 2022 probably work just as well.
set winkit="C:\Program Files (x86)\Windows Kits\10\Include\10.0.19041.0"
set   msvc="C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Tools\MSVC\14.29.30133"

:: Spaces on either side of the = are not allowed because batch sucks

:: --- May need to be modified ---

if not exist %winkit%\ (
    echo The directory %winkit% does not exist on this pc.
    echo Please modify this script and replace the path with one that is valid.
    echo.
    echo If you have Visual Studio installed already then you probably just have to look at the directories on you pc and change some version numbers around to the ones that are there.
    exit /b 1
)

if not exist %msvc%\ (
    echo The directory %msvc% does not exist on this pc.
    echo Please modify this script and replace the path with one that is valid.
    echo.
    echo If you have Visual Studio installed already then you probably just have to look at the directories on you pc and change some version numbers around to the ones that are there.
    exit /b 1
)


set msvc_binaries=%msvc%\bin\Hostx64\x64
set includes=/I%winkit%\um /I%winkit%\ucrt /I%winkit%\shared /I%msvc%\include

:: --- Setup ---
md lib 2>nul
del lib/jai_catch_windows.lib 2>nul

:: --- Compile ---
:: && short-circuits if the first command has nonzero exitcode.
%msvc_binaries%\cl.exe %includes% /c /O2 jai_catch_windows.c && %msvc_binaries%\lib.exe /OUT:"lib/jai_catch_windows.lib" jai_catch_windows.obj
if errorlevel 1 (echo Build failed.) else (echo Build successful.)

:: --- Cleanup ---
del jai_catch_windows.obj 2>nul

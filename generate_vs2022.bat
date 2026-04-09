@echo off
setlocal

rem Generate a Visual Studio 2022 solution for SARibbon with CMake.
rem Usage:
rem   generate_vs2022.bat
rem   generate_vs2022.bat "C:\Qt\6.8.3\msvc2022_64"
rem   generate_vs2022.bat "C:\Qt\6.8.3\msvc2022_64" build-vs2022-release Release

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
if "%SCRIPT_DIR:~-1%"=="/" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "SOURCE_DIR=%SCRIPT_DIR%"
set "QT_DIR=%~1"
set "BUILD_DIR=%~2"
set "CONFIG_NAME=%~3"

rem determine project name (folder name of the script dir)
for %%I in ("%SCRIPT_DIR%") do set "PROJECT_NAME=%%~nI"
rem target platform (matches generator -A)
set "PLATFORM=x64"

if not defined CONFIG_NAME set "CONFIG_NAME=Debug"
if not defined BUILD_DIR set "BUILD_DIR=Build\SARibbonVS2022"

if not defined QT_DIR if defined QT6_8_x64 set "QT_DIR=%QT6_8_x64%"

where cmake >nul 2>nul
if errorlevel 1 (
    echo [ERROR] cmake not found. Please install CMake and make sure it is in PATH.
    exit /b 1
)

if defined QT_DIR (
    if "%QT_DIR:~-1%"=="\" set "QT_DIR=%QT_DIR:~0,-1%"
    if "%QT_DIR:~-1%"=="/" set "QT_DIR=%QT_DIR:~0,-1%"
    if not exist "%QT_DIR%" (
        echo [ERROR] Qt directory does not exist: "%QT_DIR%"
        exit /b 1
    )
) else (
    echo [ERROR] Qt path is not set.
    echo [HINT] Set environment variable QT6_8_x64 or pass Qt path as the first argument.
    exit /b 1
)

if not exist "%SOURCE_DIR%\CMakeLists.txt" (
    echo [ERROR] CMakeLists.txt not found in "%SOURCE_DIR%"
    exit /b 1
)

rem Build root: use parent directory of the script dir so the build folder is a sibling of ThirdParty-SARibbon
set "BUILD_ROOT=%SCRIPT_DIR%\.."

rem Full build directory path
set "FULL_BUILD_DIR=%BUILD_ROOT%\%BUILD_DIR%"

if not exist "%FULL_BUILD_DIR%" (
    mkdir "%FULL_BUILD_DIR%"
    if errorlevel 1 (
        echo [ERROR] Failed to create build directory: "%FULL_BUILD_DIR%"
        exit /b 1
    )
)

echo [INFO] Source dir : "%SOURCE_DIR%"
echo [INFO] Build dir  : "%FULL_BUILD_DIR%"
echo [INFO] Generator  : Visual Studio 17 2022
echo [INFO] Platform   : %PLATFORM%
echo [INFO] Config     : %CONFIG_NAME%
if defined QT_DIR echo [INFO] Qt dir     : "%QT_DIR%"

cmake -S "%SOURCE_DIR%" -B "%FULL_BUILD_DIR%" -G "Visual Studio 17 2022" -A %PLATFORM% "-DCMAKE_PREFIX_PATH=%QT_DIR%"
if errorlevel 1 (
    echo [ERROR] Failed to generate Visual Studio solution.
    echo [HINT] Check environment variable QT6_8_x64 or run:
    echo        generate_vs2022.bat "C:\Qt\6.8.3\msvc2022_64"
    exit /b 1
)

echo [INFO] Solution generated successfully.
echo [INFO] Open "%FULL_BUILD_DIR%\SARibbon.sln"
echo [INFO] Or build with:
echo        cmake --build "%FULL_BUILD_DIR%" --config %CONFIG_NAME%

exit /b 0

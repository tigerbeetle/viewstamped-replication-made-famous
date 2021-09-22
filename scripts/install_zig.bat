@echo off

:: The default release is 8.0.0
set ZIG_RELEASE=0.8.0

if "%~1"=="latest" (
    :: The release can be set to the latest build
    set ZIG_RELEASE=builds
    echo Installing Zig latest build...
) else (
    echo Installing Zig %ZIG_RELEASE% release build...
)

:: Windows x86_64 architechture assumed
set ZIG_ARCH=x86_64

:: This script is for the Windows operating system:
set ZIG_OS=windows

set ZIG_TARGET=zig-%ZIG_OS%-%ZIG_ARCH%

:: Determine the build, split the JSON line on whitespace and extract the 2nd field:
for /f "tokens=2" %%a in ('curl --silent https://ziglang.org/download/index.json ^| findstr %ZIG_TARGET% ^| findstr %ZIG_RELEASE%' ) do (
    set ZIG_URL=%%a
)
:: Then remove quotes and commas:
for /f %%b in ("%ZIG_URL:,=%") do (
    set ZIG_URL=%%~b
)

:: Work out the directory and filename (with the ".zip" file extension) from the URL:
for /f %%i in ("%ZIG_URL%") do (
    set ZIG_DIRECTORY=%%~ni
    set ZIG_TARBALL=%%~nxi
)

:: Download, making sure we download to the same output document, without wget adding "-1" etc. if the file was previously partially downloaded:
echo Downloading %ZIG_URL%...
if exist %ZIG_TARBALL% (
  del /Q %ZIG_TARBALL%
)
curl --silent --progress-bar --output %ZIG_TARBALL% %ZIG_URL%

:: Replace any existing Zig installation so that we can install or upgrade:
echo Removing any existing 'zig' or '%ZIG_DIRECTORY%' folders before extracting.
if exist %ZIG_DIRECTORY% (
  rd /S /Q %ZIG_DIRECTORY%
)
if exist zig (
  rd /S /Q zig
)

:: Extract and then remove the downloaded tarball:
echo Extracting %ZIG_TARBALL%...
powershell -Command "Expand-Archive %ZIG_TARBALL% -DestinationPath ."
echo Installing %ZIG_DIRECTORY% to 'zig' in current working directory...
ren %ZIG_DIRECTORY% zig
:: Removes the zip file
del %ZIG_TARBALL%

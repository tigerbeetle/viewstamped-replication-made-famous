@echo off

:: The default release is 0.8.1
set DEFAULT_RELEASE=0.8.1

:: Determining the Zig version
if "%~1"=="" (
    set ZIG_RELEASE=%DEFAULT_RELEASE%
) else if "%~1"=="latest" (
    set ZIG_RELEASE=builds
) else (
    set ZIG_RELEASE=%~1
)

:: Checks format of release version.
echo %ZIG_RELEASE% > %TMP%\zig-temp.txt
findstr /b /r /c:"builds" /c:"^[0-9][0-9]*.[0-9][0-9]*.[0-9][0-9]*" %TMP%\zig-temp.txt >nul 2>&1
if not %ERRORLEVEL%==0 (
  echo Unexpected release format.
  del /q %TMP%\zig-temp.txt
  goto :error
)
del /q %TMP%\zig-temp.txt

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

:: Checks that the ZIG_URL variable follows the expected format.
echo %ZIG_URL% > %TMP%\zig-temp.txt
findstr /b /r /c:"https://ziglang.org/builds/" /c:"https://ziglang.org/download/%ZIG_RELEASE%"  %TMP%\zig-temp.txt >nul 2>&1
if not %ERRORLEVEL%==0 (
  echo The URL to download the zip file is has an unexpected format.
  echo This may mean that the %ZIG_RELEASE% release has not been not found on ziglang.org.
  del /q %TMP%\zig-temp.txt
  goto :error
)
del /q %TMP%\zig-temp.txt

:: The URL is valid and zig is being installed
if "%ZIG_RELEASE%"=="builds" (
    echo Installing Zig latest build...
) else (
    echo Installing Zig %ZIG_RELEASE% release build...
)

:: Work out the directory and filename (with the ".zip" file extension) from the URL:
for /f %%i in ("%ZIG_URL%") do (
    set ZIG_DIRECTORY=%%~ni
    set ZIG_TARBALL=%%~nxi
)

:: Checks that the ZIG_DIRECTORY variable follows the expected format.
echo %ZIG_DIRECTORY% > %TMP%\zig-temp.txt
findstr /b /r /c:"zig-win64-" /c:"zig-windows-x86_64-"  %TMP%\zig-temp.txt >nul 2>&1
if not %ERRORLEVEL%==0 (
  echo The directory name for extracting the zip file is unexpected.
  echo Directory name: %ZIG_DIRECTORY%
  del /q %TMP%\zig-temp.txt
  goto :error
)
del /q %TMP%\zig-temp.txt

:: Making sure we download to the same output document, without wget adding "-1" etc. if the file was previously partially downloaded:
if exist %ZIG_TARBALL% (
  del /q %ZIG_TARBALL%
  if not %ERRORLEVEL%==0 (
    echo Cannot delete %ZIG_TARBALL%.
    goto :error
  ) else if exist %ZIG_TARBALL% (
    echo Failed to delete %ZIG_TARBALL%.
    exit
  )
)

echo Downloading %ZIG_URL%...
curl --silent --progress-bar --output %ZIG_TARBALL% %ZIG_URL%
if not %ERRORLEVEL%==0 (
  echo Cannot download Zig zip file.
  goto :error
) else if not exist  %ZIG_TARBALL% (
  echo Failed to download Zig zip file.
  exit
)

:: Replace any existing Zig installation so that we can install or upgrade:
echo Removing any existing 'zig' and %ZIG_DIRECTORY% folders before extracting.
if exist zig\ (
  rd /s /q zig\
)
if exist zig\ (
  echo the zig directory could not be successfully deleted.
  exit
)
if exist %ZIG_DIRECTORY%\ (
  rd /s /q %ZIG_DIRECTORY%
)
if exist %ZIG_DIRECTORY% (
  echo the %ZIG_DIRECTORY% directory could not be successfully deleted.
  exit
)

:: Extract and then remove the downloaded tarball:
echo Extracting %ZIG_TARBALL%...
powershell -Command "Expand-Archive %ZIG_TARBALL% -DestinationPath ."
if not %ERRORLEVEL%==0 (
  echo Failed to extract zip file.
  goto :error
) else if not exist %ZIG_TARBALL% (
  echo Failed to extract zip file.
  exit
)

echo Installing %ZIG_DIRECTORY% to 'zig' in current working directory...
ren %ZIG_DIRECTORY% zig
if not %ERRORLEVEL%==0 (
  echo Failed to rename %ZIG_DIRECTORY% to zig.
  goto :error
) else if exist %ZIG_DIRECTORY% (
  echo Failed to rename %ZIG_DIRECTORY% to zig.
  exit
)

:: Removes the zip file
del /q %ZIG_TARBALL%
if not %ERRORLEVEL%==0 (
  echo Failed to delete %ZIG_TARBALL% file.
  goto :error
) else if exist %ZIG_TARBALL% (
  echo Failed to delete %ZIG_TARBALL% file.
  exit
)

echo "Congratulations, you have successfully installed Zig version %ZIG_RELEASE%. Enjoy!"

goto :eof

:: Returns the error code and stops the bat file execution.
:error
echo Failed with error #%ERRORLEVEL%.
exit /b %ERRORLEVEL%
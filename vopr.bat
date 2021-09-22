@echo off

:: Install Zig 0.8.0 if a zig folder does not already exist:
if not exist zig\ (
    call scripts/install_zig.bat 0.8.0
    echo Running the TigerBeetle VOPR for the first time...
    echo Visit https://www.tigerbeetle.com
)

:: If a seed is provided as an argument then replay the seed, otherwise test 1,000 seeds:
if not "%~1"=="" (
    :: Build in fast ReleaseSafe mode if required, useful where you don't need debug logging:
    if "%~2"=="-OReleaseSafe" (
        echo Replaying seed %~1 in ReleaseSafe mode...
        call zig run src/simulator.zig -OReleaseSafe -- %~1
    ) else (
        echo Replaying seed %~1 in Debug mode with full debug logging enabled...
        call zig run src/simulator.zig -ODebug -- %~1
    )
) else (
    call zig build-exe src/simulator.zig -OReleaseSafe
    for /L %%i in (1,1,1000) do (
        call simulator
    )
)

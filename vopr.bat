@echo off

:: Install Zig 0.8.0 if a zig folder does not already exist:
IF NOT EXIST zig\ (
    CALL scripts/install_zig.bat latest
    ECHO Running the TigerBeetle VOPR for the first time...
    ECHO Visit https://www.tigerbeetle.com
)

:: If a seed is provided as an argument then replay the seed, otherwise test a 1,000 seeds:
IF NOT "%~1"=="" (
    :: Build in fast ReleaseSafe mode if required, useful where you don't need debug logging:
    IF "%~2"=="-OReleaseSafe" (
        ECHO Replaying seed %~1 in ReleaseSafe mode...
        CALL zig run src/simulator.zig -OReleaseSafe -- %~1
    ) ELSE (
        ECHO Replaying seed %~1 in Debug mode with full debug logging enabled...
        CALL zig run src/simulator.zig -ODebug -- %~1
    )
) ELSE (
    CALL zig build-exe src/simulator.zig -OReleaseSafe
    for /L %%i in (1,1,1000) do (
        CALL simulator
    )
)

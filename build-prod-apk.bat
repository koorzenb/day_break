@echo off
REM exit when any command fails
@REM setlocal
setlocal EnableDelayedExpansion

@REM if this script has the following args, --no-tests, skip running tests

@REM fast Build
if "%1"=="--f" (
    @REM Killing any dart.exe processes that interfere with flutter clean
    echo Fast build as per --f argument. Skipping tests...
    call taskkill /F /IM dart.exe /T
    goto :skipTests
)

echo Running all tests...
call flutter test
if errorlevel 1 exit /b 1

:skipTests
call flutter clean
call set-build-env.bat

REM Require Tomorrow.io key explicitly (no embedded fallback)
if "%TOMORROWIO_API_KEY%"=="" (
    echo TOMORROWIO_API_KEY environment variable is not set. Aborting build.
    exit /b 1
)

set DART_DEFINES=--dart-define=TOMORROWIO_API_KEY=%TOMORROWIO_API_KEY%

@REM @REM If define_env is not configured, configure it
@REM where /q define_env
@REM if errorlevel 1 (
@REM     echo define_env could not be found
@REM     dart pub global activate define_env
@REM )

REM Create folder for build if it doesn't exist
set OUTPUT_FOLDER=release\%BUILD_VERSION%
set OUTPUT_FILE=%PROJ_NAME%-%BUILD_VERSION%.apk
echo Output file = .\%OUTPUT_FOLDER%\%OUTPUT_FILE%

if exist %OUTPUT_FOLDER%\%OUTPUT_FILE% (
    if "%1"=="--f" (
        echo .
        echo Overwriting previous build 
        goto :continueBuild
    ) else (
        call :promptUser
    )
) else (
    call :continueBuild
)

:promptUser
    set /P REPLY=Press 'y' to overwrite, or any other key to exit: 
    if /I "%REPLY%"=="Y" goto :continueBuild
    exit /b

:continueBuild
    if not exist "%OUTPUT_FOLDER%" mkdir "%OUTPUT_FOLDER%"

    @REM for /F "usebackq delims=" %%A in (`define_env --f .env.prod --no-generate ^| sed -r "s/--dart-define=/--dart-define /g"`) do call flutter build apk --release -v -t lib/main_prod.dart --obfuscate --split-debug-info=./debug-info %%A
    echo Using TOMORROWIO_API_KEY for compile-time define.

    if "%1"=="--f" (
        call flutter build apk --release %DART_DEFINES%
    ) else (
        call flutter doctor -v > flutter-doctor-win.txt 
        call flutter pub outdated >> flutter-doctor-win.txt
    call flutter build apk --release -v --obfuscate --split-debug-info=./debug-info --dart-define=TOMORROWIO_API_KEY
    )

    echo.

    @REM Copy the built APK to the release folder with versioned name
    if exist build\app\outputs\flutter-apk\app-release.apk (
        copy /Y build\app\outputs\flutter-apk\app-release.apk %OUTPUT_FOLDER%\%OUTPUT_FILE%
        echo Built %BUILD_VERSION% bundle to "%OUTPUT_FOLDER%"
    ) else (
        echo Build failed.
    )
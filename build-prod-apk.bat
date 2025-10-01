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

if "%OPENWEATHER_API_KEY%"=="" (
    echo [ERROR] OPENWEATHER_API_KEY environment variable is not set.
    echo         Set it in your shell before running this script, e.g.
    echo         set OPENWEATHER_API_KEY=your_key_here
    exit /b 1
)

REM Prepare dart-define flags (future: append more here)
set DART_DEFINES=--dart-define=OPENWEATHER_API_KEY=%OPENWEATHER_API_KEY%

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
    echo Using OPENWEATHER_API_KEY (length: %OPENWEATHER_API_KEY:~0,0%%OPENWEATHER_API_KEY:~0,1%*) for compile-time define.

    if "%1"=="--f" (
        call flutter build apk --release %DART_DEFINES%
    ) else (
        call flutter doctor -v > flutter-doctor-win.txt 
        call flutter pub outdated >> flutter-doctor-win.txt
        call flutter build apk --release -v --obfuscate --split-debug-info=./debug-info --dart-define=OPENWEATHER_API_KEY
    )

    echo.

    @REM Copy the built APK to the release folder with versioned name
    if exist build\app\outputs\flutter-apk\app-release.apk (
        copy /Y build\app\outputs\flutter-apk\app-release.apk %OUTPUT_FOLDER%\%OUTPUT_FILE%
        echo Built %BUILD_VERSION% bundle to "%OUTPUT_FOLDER%"
    ) else (
        echo Build failed.
    )
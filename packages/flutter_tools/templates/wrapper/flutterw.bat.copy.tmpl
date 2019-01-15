@if "%DEBUG%" == "" @echo off
@rem ##########################################################################
@rem
@rem  Flutter startup script for Windows
@rem
@rem ##########################################################################

@rem Set local scope for the variables with windows NT shell
if "%OS%"=="Windows_NT" setlocal

set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set FLUTTER_APP_HOME=%DIRNAME%

set FLUTTER_WRAPPER_PROPERTIES=%FLUTTER_APP_HOME%flutter\wrapper\flutter-wrapper.properties
set FLUTTER_SDK_PATH=%USERPROFILE%\AppData\Local\Flutter

if not exist %FLUTTER_WRAPPER_PROPERTIES% (
	echo.
	echo ERROR: The %FLUTTER_WRAPPER_PROPERTIES% file can not be found.
	echo.
	echo Please execute the 'flutter wrapper' command to generate it.
	echo.
	goto fail
)

FOR /F "tokens=1* delims==" %%A IN (%FLUTTER_WRAPPER_PROPERTIES%) DO (
    IF "%%A"=="distributionUrl" set distributionUrl=%%B
    IF "%%A"=="flutterVersion" set flutterVersion=%%B
)

if "%distributionUrl%" == "" goto illegal
if "%flutterVersion%" == "" goto illegal

goto verify_flutter

:illegal
echo.
echo ERROR: The distributionUrl and flutterVersion values can not be empty in the 'flutter-wrapper.properties' file. Please specify a value, such as:
echo.
echo distributionUrl=https://github.com/flutter/flutter.git
echo flutterVersion=v1.0.0
echo.
goto fail

:verify_flutter
if not exist %FLUTTER_SDK_PATH% mkdir %FLUTTER_SDK_PATH% >NUL 2>&1
set flutter_executable=%FLUTTER_SDK_PATH%\%flutterVersion%\flutter\bin\flutter.bat
set flutter_version=%FLUTTER_SDK_PATH%\%flutterVersion%\flutter\version
set flutter_cache=%FLUTTER_SDK_PATH%\%flutterVersion%\flutter\bin\cache
set flutter_home_dir=%FLUTTER_SDK_PATH%\%flutterVersion%
set flutter_home=%flutter_home_dir%\flutter

set FLUTTER_SDK_HOME=%flutter_home%
if not exist %flutter_version% goto download
if not exist %flutter_executable% goto download
goto check

:download
git --version >NUL 2>&1
if "%ERRORLEVEL%" EQU "0" (
	if exist %flutter_home_dir% (
		rmdir /S %flutter_home_dir% >NUL 2>&1
	)
	if not exist %flutter_home% mkdir %flutter_home% >NUL 2>&1
	git clone -b %flutterVersion% %distributionUrl% %flutter_home%
) else (
	echo.
	echo ERROR: Git is not installed in your system and no 'git' command could be found in your PATH.
	echo.
	goto fail
)

:check
if not exist %flutter_cache% (
	%flutter_executable% doctor
)

:execute
%FLUTTER_SDK_HOME%\bin\flutter.bat %*

:end
@rem End local scope for the variables with windows NT shell
if "%ERRORLEVEL%" EQU "0" goto mainEnd

:fail
exit /b 1

:mainEnd
if "%OS%"=="Windows_NT" endlocal

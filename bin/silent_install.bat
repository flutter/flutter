::
:: Copyright (c) 2020 Intel Corporation
::
:: Redistribution and use in source and binary forms, with or without
:: modification, are permitted provided that the following conditions are met:
::
::   1. Redistributions of source code must retain the above copyright notice,
::      this list of conditions and the following disclaimer.
::
::   2. Redistributions in binary form must reproduce the above copyright
::      notice, this list of conditions and the following disclaimer in the
::      documentation and/or other materials provided with the distribution.
::
::   3. Neither the name of the copyright holder nor the names of its
::      contributors may be used to endorse or promote products derived from
::      this software without specific prior written permission.
::
:: THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
:: AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
:: IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
:: ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
:: LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
:: CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
:: SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
:: INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
:: CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
:: ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
:: POSSIBILITY OF SUCH DAMAGE.
::

@echo off

set this=%~n0
set exit_code=0
set action=install
set log=
set silent_log=
set version=
set timestamp=

:parse_args
    if [%1]==[] (
        goto %action%
    )
    if [%1]==[-u] (
        set action=uninstall
        shift
        goto parse_args
    )
    if [%1]==[-v] (
        set action=version
        shift
        goto parse_args
    )
    if [%1]==[-log] (
        if [%2]==[] goto invalid_params
        type nul > "%2" && set silent_log=%2
        shift
        shift
        goto parse_args
    )
    if [%1]==[-m] (
        :: This option is for compatibility only
        if [%2]==[] goto invalid_params
        shift
        shift
        goto parse_args
    )
    if [%1]==[-h] (
        set action=help
        shift
        goto parse_args
    )
    goto invalid_option

:invalid_option
    echo %this%: Invalid option: %1
    exit /b 1

:invalid_params
    echo %this%: Invalid parameter for %1
    exit /b 1

:install
    for %%i in (%~dp0haxm-*-setup.exe) do set installer=%%i
    for %%i in ("%installer%") do set filename=%%~nxi
    for /f "tokens=2 delims=-" %%i in ("%filename%") do set version=%%i
    call :log Start to install HAXM v%version%
    if exist %installer% %installer% /S
    if %errorlevel% equ 5 (
        :: Cancelled UAC confirmation dialog when not running as administrator
        call :log User canceled
        set exit_code=1
        goto in_exit
    )
    for %%i in (haxm_install-*.log) do set log=%%i
    call :log Log saved: %TEMP%\%log%
    if %errorlevel% equ 2 (
        echo Intel HAXM installation failed!
        echo For more details, please check the installation log: %TEMP%\%log%
        set exit_code=1
        goto in_exit
    )
    set /a status="%errorlevel% & 0x0f"
    set /a method="%errorlevel% & 0xf0"
    if %method% equ 0 (
        set installed=installed
    ) else if %method% equ 0x10 (
        set installed=reinstalled
    ) else if %method% equ 0x20 (
        set installed=upgraded
    ) else goto in_exit
    if %status% equ 0x01 (
        echo Intel HAXM is %installed% but cannot be used until the system settings are ready.
        echo For more details, please check the installation log: %TEMP%\%log%
        goto in_exit
    )
    echo Intel HAXM %installed% successfully!
:in_exit
    if exist %log% del /f %log%
    call :log End of installation
    exit /b %exit_code%

:uninstall
    call :get_installed_version
    if not "%version%"=="" call :log Start to uninstall HAXM v%version%
    set install_path="%ProgramFiles%\Intel\HAXM"
    set uninstaller=%install_path%\uninstall.exe
    if not exist %uninstaller% (
        echo Intel HAXM is not installed.
        call :log HAXM not found
        goto un_exit
    )
    :: Run below command to check if running as administrator
    net session >nul 2>&1 || goto un_fail
    :: Add _?= to execute uninstaller synchronously.
    :: By default, the uninstaller copies itself to the temporary directory and
    :: run asynchronously there.
    %uninstaller% /S _?=%ProgramFiles%\Intel\HAXM
    for %%i in (haxm_uninstall-*.log) do set log=%%i
    call :log Log saved: %TEMP%\%log%
    if %errorlevel% equ 2 (
        echo Intel HAXM uninstallation failed!
        echo Please terminate the running virtual machine processes first.
        set exit_code=1
        goto un_exit
    )
    :: Rename installation folder to check if any files are locked.
    for %%i in (0, 1, 2) do (
        ren %install_path% HAXM 2>nul && goto break || timeout 5 >nul
    )
    echo Intel HAXM uninstallation failed!
    echo For more details, please check the installation log: %TEMP%\%log%
    set exit_code=1
    goto un_exit
    :break
    if exist %install_path% rmdir /s /q %install_path%
    echo Intel HAXM uninstalled successfully!
    goto un_exit
:un_fail
    call :log Permission denied
    echo Please run this command as administrator!
    set exit_code=1
:un_exit
    if exist %log% del /f %log%
    call :log End of uninstallation
    exit /b %exit_code%

:version
    call :get_installed_version
    if "%version%"=="" exit /b 1
    echo %version%
    exit /b 0

:get_installed_version
    set reg_haxm=
    set reg_products=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products
    for /f %%i in ('reg query "%reg_products%"') do (
        reg query %%i /s /v DisplayName ^
            | findstr /c:"Hardware Accelerated Execution Manager" >nul ^
            && set reg_haxm=%%i && goto installed
    )
:installed
    if "%reg_haxm%"=="" exit /b
    for /f "tokens=3" %%i in ('reg query "%reg_haxm%" /s /v DisplayVersion') do (
        set version=%%i
        exit /b
    )
    exit /b

:log
    if "%silent_log%"=="" exit /b
    for /f "tokens=2" %%i in ("%date%") do set d=%%i
    for /f "tokens=1" %%i in ("%time%") do set t=%%i
    set timestamp=%d% %t%
    echo [%timestamp%] %*>> "%silent_log%"
    exit /b

:help
    echo Usage: silent_install.bat [-u^|-v^|-h] [-log file_path]
    echo:
    echo silent_install.bat installs or uninstalls Intel HAXM in silent mode.
    echo This batch file is required to run as administrator.
    echo:
    echo   The default action is to install Intel HAXM on your computer.
    echo   -u        uninstall Intel HAXM from your computer
    echo   -v        print installed HAXM version
    echo   -log      save log information to the specified file
    echo   -h        show help information
    exit /b 0

:: This script adds cygwin to the path
@echo OFF

set "PATH=%~dp0\..\..\..\..\..\..\third_party\cygwin\bin;%PATH%"
:: Make sure systems with non-depot_tools python can still find modules that
:: were previously included via python_26/Lib/site-packages.
set "PYTHONPATH=%~dp0\..\..\..\..\..\..\tools\python;%PYTHONPATH%"

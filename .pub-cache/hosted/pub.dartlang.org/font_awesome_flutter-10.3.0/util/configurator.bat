@echo off
pushd %~dp0
cd ..
dart .\util\lib\main.dart %* & ^
popd

cd "$Env:CIRRUS_WORKING_DIR\packages\flutter_tools"

& "$Env:CIRRUS_WORKING_DIR\bin\cache\dart-sdk\bin\pub.bat" run build_runner build

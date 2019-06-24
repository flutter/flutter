cd "$Env:CIRRUS_WORKING_DIR\packages\flutter_tools"

& "$Env:CIRRUS_WORKING_DIR\bin\cache\dart-sdk\bin\pub.exe" run build_runner build

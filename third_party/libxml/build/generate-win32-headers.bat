REM Generate config.h and xmlversion.h.  We put the generated files in
REM win32 so they don't get included on other platforms.

cd %~dp0\..\win32
cscript //E:jscript configure.js compiler=msvc iconv=no icu=yes
move ..\config.h .

md include\libxml
move ..\include\libxml\xmlversion.h include\libxml\

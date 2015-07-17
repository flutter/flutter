<html>
<body>
<pre>
<h1>Build Log</h1>
<h3>
--------------------Configuration: libxml2 - Win32 (WCE x86em) Debug--------------------
</h3>
<h3>Command Lines</h3>
Creating temporary file "C:\DOCUME~1\fjvg\CONFIG~1\Temp\RSP12E.tmp" with contents
[
/nologo /W3 /Zi /Od /I "..\..\..\include" /I "..\..\include" /I "c:\ppc\libxml\XML\win32\wince" /D "DEBUG" /D _WIN32_WCE=300 /D "WIN32" /D "STRICT" /D "_WIN32_WCE_EMULATION" /D "INTERNATIONAL" /D "USA" /D "INTLMSG_CODEPAGE" /D "WIN32_PLATFORM_PSPC" /D "i486" /D UNDER_CE=300 /D "UNICODE" /D "_UNICODE" /D "_X86_" /D "x86" /Fp"X86EMDbg/libxml2.pch" /YX /Fo"X86EMDbg/" /Fd"X86EMDbg/" /Gz /c 
"C:\ppc\libxml\XML\DOCBparser.c"
"C:\ppc\libxml\XML\encoding.c"
"C:\ppc\libxml\XML\entities.c"
"C:\ppc\libxml\XML\error.c"
"C:\ppc\libxml\XML\globals.c"
"C:\ppc\libxml\XML\hash.c"
"C:\ppc\libxml\XML\list.c"
"C:\ppc\libxml\XML\parser.c"
"C:\ppc\libxml\XML\parserInternals.c"
"C:\ppc\libxml\XML\SAX.c"
"C:\ppc\libxml\XML\threads.c"
"C:\ppc\libxml\XML\tree.c"
"C:\ppc\libxml\XML\uri.c"
"C:\ppc\libxml\XML\valid.c"
"C:\ppc\libxml\XML\win32\wince\wincecompat.c"
"C:\ppc\libxml\XML\xlink.c"
"C:\ppc\libxml\XML\xmlIO.c"
"C:\ppc\libxml\XML\xmlmemory.c"
"C:\ppc\libxml\XML\c14n.c"
"C:\ppc\libxml\XML\catalog.c"
"C:\ppc\libxml\XML\debugXML.c"
"C:\ppc\libxml\XML\HTMLparser.c"
"C:\ppc\libxml\XML\HTMLtree.c"
"C:\ppc\libxml\XML\nanoftp.c"
"C:\ppc\libxml\XML\nanohttp.c"
"C:\ppc\libxml\XML\xinclude.c"
"C:\ppc\libxml\XML\xpath.c"
"C:\ppc\libxml\XML\xpointer.c"
]
Creating command line "cl.exe @C:\DOCUME~1\fjvg\CONFIG~1\Temp\RSP12E.tmp" 
Creating temporary file "C:\DOCUME~1\fjvg\CONFIG~1\Temp\RSP12F.tmp" with contents
[
corelibc.lib winsock.lib commctrl.lib coredll.lib /nologo /stack:0x10000,0x1000 /dll /incremental:yes /pdb:"X86EMDbg/libxml2.pdb" /debug /nodefaultlib:"OLDNAMES.lib" /nodefaultlib:libc.lib /nodefaultlib:libcd.lib /nodefaultlib:libcmt.lib /nodefaultlib:libcmtd.lib /nodefaultlib:msvcrt.lib /nodefaultlib:msvcrtd.lib /nodefaultlib:oldnames.lib /def:".\libxml2.def" /out:"X86EMDbg/libxml2.dll" /implib:"X86EMDbg/libxml2.lib" /windowsce:emulation /MACHINE:IX86 
.\X86EMDbg\DOCBparser.obj
.\X86EMDbg\encoding.obj
.\X86EMDbg\entities.obj
.\X86EMDbg\error.obj
.\X86EMDbg\globals.obj
.\X86EMDbg\hash.obj
.\X86EMDbg\list.obj
.\X86EMDbg\parser.obj
.\X86EMDbg\parserInternals.obj
.\X86EMDbg\SAX.obj
.\X86EMDbg\threads.obj
.\X86EMDbg\tree.obj
.\X86EMDbg\uri.obj
.\X86EMDbg\valid.obj
.\X86EMDbg\wincecompat.obj
.\X86EMDbg\xlink.obj
.\X86EMDbg\xmlIO.obj
.\X86EMDbg\xmlmemory.obj
.\X86EMDbg\c14n.obj
.\X86EMDbg\catalog.obj
.\X86EMDbg\debugXML.obj
.\X86EMDbg\HTMLparser.obj
.\X86EMDbg\HTMLtree.obj
.\X86EMDbg\nanoftp.obj
.\X86EMDbg\nanohttp.obj
.\X86EMDbg\xinclude.obj
.\X86EMDbg\xpath.obj
.\X86EMDbg\xpointer.obj
]
Creating command line "link.exe @C:\DOCUME~1\fjvg\CONFIG~1\Temp\RSP12F.tmp"
<h3>Output Window</h3>
Compiling...
DOCBparser.c
encoding.c
entities.c
error.c
globals.c
hash.c
list.c
parser.c
C:\ppc\libxml\XML\parser.c(2282) : warning C4090: '=' : different 'const' qualifiers
parserInternals.c
SAX.c
threads.c
tree.c
uri.c
valid.c
wincecompat.c
C:\ppc\libxml\XML\win32\wince\wincecompat.c(37) : warning C4047: '=' : 'char ' differs in levels of indirection from 'char [2]'
C:\ppc\libxml\XML\win32\wince\wincecompat.c(39) : warning C4047: '=' : 'char ' differs in levels of indirection from 'char [2]'
C:\ppc\libxml\XML\win32\wince\wincecompat.c(40) : warning C4047: 'return' : 'int ' differs in levels of indirection from 'void *'
xlink.c
xmlIO.c
C:\ppc\libxml\XML\xmlIO.c(2404) : warning C4101: 'dir' : unreferenced local variable
C:\ppc\libxml\XML\xmlIO.c(2405) : warning C4101: 'cur' : unreferenced local variable
xmlmemory.c
c14n.c
catalog.c
debugXML.c
HTMLparser.c
HTMLtree.c
nanoftp.c
nanohttp.c
C:\ppc\libxml\XML\nanoftp.c(892) : warning C4761: integral size mismatch in argument; conversion supplied
xinclude.c
C:\ppc\libxml\XML\nanohttp.c(921) : warning C4761: integral size mismatch in argument; conversion supplied
xpath.c
xpointer.c
Linking...
   Creating library X86EMDbg/libxml2.lib and object X86EMDbg/libxml2.exp



<h3>Results</h3>
libxml2.dll - 0 error(s), 8 warning(s)
</pre>
</body>
</html>

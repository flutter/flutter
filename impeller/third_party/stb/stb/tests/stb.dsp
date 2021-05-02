# Microsoft Developer Studio Project File - Name="stb" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=stb - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "stb.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "stb.mak" CFG="stb - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "stb - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "stb - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "stb - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /G6 /MT /W3 /GX /Z7 /O2 /Ob2 /I ".." /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /D "TT_TEST" /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386

!ELSEIF  "$(CFG)" == "stb - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug\stb"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /GZ /c
# ADD CPP /nologo /MTd /W3 /GX /Zi /Od /I ".." /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /D "MAIN_TEST" /FR /FD /GZ /c
# SUBTRACT CPP /YX
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /incremental:no /debug /machine:I386 /pdbtype:sept
# SUBTRACT LINK32 /force

!ENDIF 

# Begin Target

# Name "stb - Win32 Release"
# Name "stb - Win32 Debug"
# Begin Source File

SOURCE=..\docs\other_libs.md
# End Source File
# Begin Source File

SOURCE=.\stb.c
# End Source File
# Begin Source File

SOURCE=..\stb.h
# End Source File
# Begin Source File

SOURCE=..\stb_c_lexer.h
# End Source File
# Begin Source File

SOURCE=..\stb_divide.h
# End Source File
# Begin Source File

SOURCE=..\stb_dxt.h
# End Source File
# Begin Source File

SOURCE=..\stb_easy_font.h
# End Source File
# Begin Source File

SOURCE=..\stb_herringbone_wang_tile.h
# End Source File
# Begin Source File

SOURCE=..\stb_image.h
# End Source File
# Begin Source File

SOURCE=..\stb_image_resize.h
# End Source File
# Begin Source File

SOURCE=..\stb_image_write.h
# End Source File
# Begin Source File

SOURCE=..\stb_leakcheck.h
# End Source File
# Begin Source File

SOURCE=..\stb_malloc.h
# End Source File
# Begin Source File

SOURCE=..\stb_perlin.h
# End Source File
# Begin Source File

SOURCE=..\stb_rect_pack.h
# End Source File
# Begin Source File

SOURCE=..\stb_textedit.h
# End Source File
# Begin Source File

SOURCE=..\stb_tilemap_editor.h
# End Source File
# Begin Source File

SOURCE=..\stb_truetype.h
# End Source File
# Begin Source File

SOURCE=..\stb_vorbis.c
# End Source File
# Begin Source File

SOURCE=..\stb_voxel_render.h
# End Source File
# Begin Source File

SOURCE=..\stretchy_buffer.h
# End Source File
# Begin Source File

SOURCE=.\stretchy_buffer_test.c
# End Source File
# Begin Source File

SOURCE=.\test_c_compilation.c
# End Source File
# Begin Source File

SOURCE=.\test_truetype.c
# End Source File
# Begin Source File

SOURCE=.\test_vorbis.c
# End Source File
# Begin Source File

SOURCE=.\textedit_sample.c
# End Source File
# End Target
# End Project

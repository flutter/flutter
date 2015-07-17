
 LIBXML2 build system for Win32 README
 -------------------------------------

 In this folder are stored all the files required to compile LIBXML2 with win32 compilers.
 Bakefile (http://bakefile.sourceforge.net) is used as makefile generator.

 Supported makefiles:
 - makefile.vc     for Microsoft NMAKE
 - makefile.bcc    for Borland MAKE
 - makefile.wat    for OpenWatcom MAKE
 - makefile.gcc    for MinGW MINGW32-MAKE
 - all DSP & DSW   for Microsoft VisualC++ 6.0 (can be used also with VS.NET AFAIK)

 This readme is organized as:
   1.0 HOWTO compile LIBXML2 using makefiles     <-- for users who want to build the library using *command-line*
   1.1 HOWTO compile LIBXML2 using an IDE        <-- for users who want to build the library using an *IDE*
   1.2 HOWTO regenerate makefiles for LIBXML2    <-- for libxml2 mantainers/developers/advanced users

 If you just want to compile the library (and the test programs) you should definitely avoid the
 section 1.1 and focus on the 1.0.
 





 1.0 HOWTO compile LIBXML2 using makefiles
 -----------------------------------------
 
 Choose your preferred compiler among those actually supported (see above) and then run
 
                              mycompilermake -fmakefile.makefileext [options]

 for a full list of the available options you should open with a notepad (or something like that)
 the makefile you want to use; at the beginning you should see a section which starts as:

     # -------------------------------------------------------------------------
     # These are configurable options:
     # -------------------------------------------------------------------------

 here you can find all the options actually used by that makefile. 
 They can be customized when running the makefile writing something like:

 nmake -fmakefile.vc BUILD=release
 mingw32-make -fmakefile.gcc BUILD=debug ICONV_DIR=c:\myiconv

 or they can be permanently changed modifying the makefile.
 That's all: for any problem/compile-error/suggestion, write to 
 frm@users.sourceforge.net with the word "libxml2" in the subject.





 1.1 HOWTO compile LIBXML2 using an IDE
 --------------------------------------
 
 Actually only the Microsoft VisualC++ 6.0 project files are generated.
 In future other Integrated Development Environments (IDEs) will be supported as well.
 
 With MSVC++ 6.0, you should open the DSW file and then set as the active project the
 "libxml2" project, if you want to build the library or one of the test projects if you
 want to run them.
 Using the command "Build->Set Active Configuration" you can choose one of the predefined
 configuration.





 1.2 HOWTO regenerate makefiles for LIBXML2
 ------------------------------------------
 
 Be sure to have installed Bakefile (http://bakefile.sourceforge.net).
 Just run the "bakefile_gen" command inside the folder containing the "libxml2.bkl" file.
 NOTE: if you want to remove all the makefiles, you can use the "bakefile_gen -c" command.
 
 The template files used to generate all makefiles are only two:
 - libxml2.bkl      (the main one)
 - Bakefiles.bkgen
 All the other files can be dinamically regenerated.





 If you have problems with the compilation of LIBXML2 under windows (using one of the supported compiler)
 please write to:

     Francesco Montorsi <frm@users.sourceforge.net>


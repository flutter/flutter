
                        Expat, Release 2.1.0

This is Expat, a C library for parsing XML, written by James Clark.
Expat is a stream-oriented XML parser.  This means that you register
handlers with the parser before starting the parse.  These handlers
are called when the parser discovers the associated structures in the
document being parsed.  A start tag is an example of the kind of
structures for which you may register handlers.

Windows users should use the expat_win32bin package, which includes
both precompiled libraries and executables, and source code for
developers.

Expat is free software.  You may copy, distribute, and modify it under
the terms of the License contained in the file COPYING distributed
with this package.  This license is the same as the MIT/X Consortium
license.

Versions of Expat that have an odd minor version (the middle number in
the release above), are development releases and should be considered
as beta software.  Releases with even minor version numbers are
intended to be production grade software.

If you are building Expat from a check-out from the CVS repository,
you need to run a script that generates the configure script using the
GNU autoconf and libtool tools.  To do this, you need to have
autoconf 2.58 or newer. Run the script like this:

        ./buildconf.sh

Once this has been done, follow the same instructions as for building
from a source distribution.

To build Expat from a source distribution, you first run the
configuration shell script in the top level distribution directory:

        ./configure

There are many options which you may provide to configure (which you
can discover by running configure with the --help option).  But the
one of most interest is the one that sets the installation directory.
By default, the configure script will set things up to install
libexpat into /usr/local/lib, expat.h into /usr/local/include, and
xmlwf into /usr/local/bin.  If, for example, you'd prefer to install
into /home/me/mystuff/lib, /home/me/mystuff/include, and
/home/me/mystuff/bin, you can tell configure about that with:

        ./configure --prefix=/home/me/mystuff
        
Another interesting option is to enable 64-bit integer support for
line and column numbers and the over-all byte index:

        ./configure CPPFLAGS=-DXML_LARGE_SIZE
        
However, such a modification would be a breaking change to the ABI
and is therefore not recommended for general use - e.g. as part of
a Linux distribution - but rather for builds with special requirements.

After running the configure script, the "make" command will build
things and "make install" will install things into their proper
location.  Have a look at the "Makefile" to learn about additional
"make" options.  Note that you need to have write permission into
the directories into which things will be installed.

If you are interested in building Expat to provide document
information in UTF-16 encoding rather than the default UTF-8, follow
these instructions (after having run "make distclean"):

        1. For UTF-16 output as unsigned short (and version/error
           strings as char), run:

               ./configure CPPFLAGS=-DXML_UNICODE

           For UTF-16 output as wchar_t (incl. version/error strings),
           run:

               ./configure CFLAGS="-g -O2 -fshort-wchar" \
                           CPPFLAGS=-DXML_UNICODE_WCHAR_T

        2. Edit the MakeFile, changing:

               LIBRARY = libexpat.la

           to:

               LIBRARY = libexpatw.la

           (Note the additional "w" in the library name.)

        3. Run "make buildlib" (which builds the library only).
           Or, to save step 2, run "make buildlib LIBRARY=libexpatw.la".

        4. Run "make installlib" (which installs the library only).
           Or, if step 2 was omitted, run "make installlib LIBRARY=libexpatw.la".
           
Using DESTDIR or INSTALL_ROOT is enabled, with INSTALL_ROOT being the default
value for DESTDIR, and the rest of the make file using only DESTDIR.
It works as follows:
   $ make install DESTDIR=/path/to/image
overrides the in-makefile set DESTDIR, while both
   $ INSTALL_ROOT=/path/to/image make install
   $ make install INSTALL_ROOT=/path/to/image
use DESTDIR=$(INSTALL_ROOT), even if DESTDIR eventually is defined in the
environment, because variable-setting priority is
1) commandline
2) in-makefile
3) environment  

Note: This only applies to the Expat library itself, building UTF-16 versions
of xmlwf and the tests is currently not supported.         

Note for Solaris users:  The "ar" command is usually located in
"/usr/ccs/bin", which is not in the default PATH.  You will need to
add this to your path for the "make" command, and probably also switch
to GNU make (the "make" found in /usr/ccs/bin does not seem to work
properly -- appearantly it does not understand .PHONY directives).  If
you're using ksh or bash, use this command to build:

        PATH=/usr/ccs/bin:$PATH make

When using Expat with a project using autoconf for configuration, you
can use the probing macro in conftools/expat.m4 to determine how to
include Expat.  See the comments at the top of that file for more
information.

A reference manual is available in the file doc/reference.html in this
distribution.

The homepage for this project is http://www.libexpat.org/.  There
are links there to connect you to the bug reports page.  If you need
to report a bug when you don't have access to a browser, you may also
send a bug report by email to expat-bugs@mail.libexpat.org.

Discussion related to the direction of future expat development takes
place on expat-discuss@mail.libexpat.org.  Archives of this list and
other Expat-related lists may be found at:

        http://mail.libexpat.org/mailman/listinfo/

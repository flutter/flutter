Protocol Buffers - Google's data interchange format
Copyright 2008 Google Inc.
http://code.google.com/apis/protocolbuffers/

C++ Installation - Unix
=======================

To build and install the C++ Protocol Buffer runtime and the Protocol
Buffer compiler (protoc) execute the following:

  $ ./configure
  $ make
  $ make check
  $ make install

If "make check" fails, you can still install, but it is likely that
some features of this library will not work correctly on your system.
Proceed at your own risk.

"make install" may require superuser privileges.

For advanced usage information on configure and make, see INSTALL.txt.

** Hint on install location **

  By default, the package will be installed to /usr/local.  However,
  on many platforms, /usr/local/lib is not part of LD_LIBRARY_PATH.
  You can add it, but it may be easier to just install to /usr
  instead.  To do this, invoke configure as follows:

    ./configure --prefix=/usr

  If you already built the package with a different prefix, make sure
  to run "make clean" before building again.

** Compiling dependent packages **

  To compile a package that uses Protocol Buffers, you need to pass
  various flags to your compiler and linker.  As of version 2.2.0,
  Protocol Buffers integrates with pkg-config to manage this.  If you
  have pkg-config installed, then you can invoke it to get a list of
  flags like so:

    pkg-config --cflags protobuf         # print compiler flags
    pkg-config --libs protobuf           # print linker flags
    pkg-config --cflags --libs protobuf  # print both

  For example:

    c++ my_program.cc my_proto.pb.cc `pkg-config --cflags --libs protobuf`

  Note that packages written prior to the 2.2.0 release of Protocol
  Buffers may not yet integrate with pkg-config to get flags, and may
  not pass the correct set of flags to correctly link against
  libprotobuf.  If the package in question uses autoconf, you can
  often fix the problem by invoking its configure script like:

    configure CXXFLAGS="$(pkg-config --cflags protobuf)" \
              LIBS="$(pkg-config --libs protobuf)"

  This will force it to use the correct flags.

  If you are writing an autoconf-based package that uses Protocol
  Buffers, you should probably use the PKG_CHECK_MODULES macro in your
  configure script like:

    PKG_CHECK_MODULES([protobuf], [protobuf])

  See the pkg-config man page for more info.

  If you only want protobuf-lite, substitute "protobuf-lite" in place
  of "protobuf" in these examples.

** Note for cross-compiling **

  The makefiles normally invoke the protoc executable that they just
  built in order to build tests.  When cross-compiling, the protoc
  executable may not be executable on the host machine.  In this case,
  you must build a copy of protoc for the host machine first, then use
  the --with-protoc option to tell configure to use it instead.  For
  example:

    ./configure --with-protoc=protoc

  This will use the installed protoc (found in your $PATH) instead of
  trying to execute the one built during the build process.  You can
  also use an executable that hasn't been installed.  For example, if
  you built the protobuf package for your host machine in ../host,
  you might do:

    ./configure --with-protoc=../host/src/protoc

  Either way, you must make sure that the protoc executable you use
  has the same version as the protobuf source code you are trying to
  use it with.

** Note for Solaris users **

  Solaris 10 x86 has a bug that will make linking fail, complaining
  about libstdc++.la being invalid.  We have included a work-around
  in this package.  To use the work-around, run configure as follows:

    ./configure LDFLAGS=-L$PWD/src/solaris

  See src/solaris/libstdc++.la for more info on this bug.

** Note for HP C++ Tru64 users **

  To compile invoke configure as follows:

    ./configure CXXFLAGS="-O -std ansi -ieee -D__USE_STD_IOSTREAM"

  Also, you will need to use gmake instead of make.

C++ Installation - Windows
==========================

If you are using Microsoft Visual C++, see vsprojects/readme.txt.

If you are using Cygwin or MinGW, follow the Unix installation
instructions, above.

Binary Compatibility Warning
============================

Due to the nature of C++, it is unlikely that any two versions of the
Protocol Buffers C++ runtime libraries will have compatible ABIs.
That is, if you linked an executable against an older version of
libprotobuf, it is unlikely to work with a newer version without
re-compiling.  This problem, when it occurs, will normally be detected
immediately on startup of your app.  Still, you may want to consider
using static linkage.  You can configure this package to install
static libraries only using:

  ./configure --disable-shared

Java and Python Installation
============================

The Java and Python runtime libraries for Protocol Buffers are located
in the java and python directories.  See the README file in each
directory for more information on how to compile and install them.
Note that both of them require you to first install the Protocol
Buffer compiler (protoc), which is part of the C++ package.

Usage
=====

The complete documentation for Protocol Buffers is available via the
web at:

  http://code.google.com/apis/protocolbuffers/

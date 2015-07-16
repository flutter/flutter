Protocol Buffers - Google's data interchange format
Copyright 2008 Google Inc.

This directory contains the Python Protocol Buffers runtime library.

Normally, this directory comes as part of the protobuf package, available
from:

  http://code.google.com/p/protobuf

The complete package includes the C++ source code, which includes the
Protocol Compiler (protoc).  If you downloaded this package from PyPI
or some other Python-specific source, you may have received only the
Python part of the code.  In this case, you will need to obtain the
Protocol Compiler from some other source before you can use this
package.

Development Warning
===================

The Python implementation of Protocol Buffers is not as mature as the C++
and Java implementations.  It may be more buggy, and it is known to be
pretty slow at this time.  If you would like to help fix these issues,
join the Protocol Buffers discussion list and let us know!

Installation
============

1) Make sure you have Python 2.4 or newer.  If in doubt, run:

     $ python -V

2) If you do not have setuptools installed, note that it will be
   downloaded and installed automatically as soon as you run setup.py.
   If you would rather install it manually, you may do so by following
   the instructions on this page:

     http://peak.telecommunity.com/DevCenter/EasyInstall#installation-instructions

3) Build the C++ code, or install a binary distribution of protoc.  If
   you install a binary distribution, make sure that it is the same
   version as this package.  If in doubt, run:

     $ protoc --version

4) Run the tests:

     $ python setup.py test

   If some tests fail, this library may not work correctly on your
   system.  Continue at your own risk.

   Please note that there is a known problem with some versions of
   Python on Cygwin which causes the tests to fail after printing the
   error:  "sem_init: Resource temporarily unavailable".  This appears
   to be a bug either in Cygwin or in Python:
     http://www.cygwin.com/ml/cygwin/2005-07/msg01378.html
   We do not know if or when it might me fixed.  We also do not know
   how likely it is that this bug will affect users in practice.

5) Install:

     $ python setup.py install

   This step may require superuser privileges.
   NOTE: To use C++ implementation, you need to install C++ protobuf runtime
   library of the same version and export the environment variable before this
   step. See the "C++ Implementation" section below for more details.

Usage
=====

The complete documentation for Protocol Buffers is available via the
web at:

  http://code.google.com/apis/protocolbuffers/

C++ Implementation
==================

WARNING: This is EXPERIMENTAL and only available for CPython platforms.

The C++ implementation for Python messages is built as a Python extension to
improve the overall protobuf Python performance.

To use the C++ implementation, you need to:
1) Install the C++ protobuf runtime library, please see instructions in the
   parent directory.
2) Export an environment variable:

  $ export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp

You need to export this variable before running setup.py script to build and
install the extension.  You must also set the variable at runtime, otherwise
the pure-Python implementation will be used. In a future release, we will
change the default so that C++ implementation is used whenever it is available.
It is strongly recommended to run `python setup.py test` after setting the
variable to "cpp", so the tests will be against C++ implemented Python
messages.


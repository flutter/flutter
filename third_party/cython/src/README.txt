Welcome to Cython!
=================

Cython (http://cython.org) is a language that makes writing C extensions for
the Python language as easy as Python itself.  Cython is based on the
well-known Pyrex, but supports more cutting edge functionality and
optimizations.

The Cython language is very close to the Python language, but Cython
additionally supports calling C functions and declaring C types on variables
and class attributes.  This allows the compiler to generate very efficient C
code from Cython code.

This makes Cython the ideal language for wrapping external C libraries, and
for fast C modules that speed up the execution of Python code.

LICENSE:

The original Pyrex program was licensed "free of restrictions" (see
below).  Cython itself is licensed under the permissive

   Apache License

See LICENSE.txt.


--------------------------

Note that Cython used to ship the full version control repository in its source
distribution, but no longer does so due to space constraints.  To get the
full source history, make sure you have git installed, then step into the
base directory of the Cython source distribution and type

    make repo

Alternatively, check out the latest developer repository from

    https://github.com/cython/cython



The following is from Pyrex:
------------------------------------------------------
This is a development version of Pyrex, a language
for writing Python extension modules.

For more info, see:

    Doc/About.html for a description of the language
    INSTALL.txt    for installation instructions
    USAGE.txt      for usage instructions
    Demos          for usage examples

Comments, suggestions, bug reports, etc. are
welcome!

Copyright stuff: Pyrex is free of restrictions. You
may use, redistribute, modify and distribute modified
versions.

The latest version of Pyrex can be found here:

http://www.cosc.canterbury.ac.nz/~greg/python/Pyrex/

Greg Ewing, Computer Science Dept, +--------------------------------------+
University of Canterbury,          | A citizen of NewZealandCorp, a       |
Christchurch, New Zealand          | wholly-owned subsidiary of USA Inc.  |
greg@cosc.canterbury.ac.nz         +--------------------------------------+

"""Code coverage measurement for Python.

Ned Batchelder
http://nedbatchelder.com/code/coverage

"""

__version__ = "3.5.1"     # see detailed history in CHANGES.txt

__url__ = "http://nedbatchelder.com/code/coverage"
if max(__version__).isalpha():
    # For pre-releases, use a version-specific URL.
    __url__ += "/" + __version__

from coverage.control import coverage, process_startup
from coverage.data import CoverageData
from coverage.cmdline import main, CoverageScript
from coverage.misc import CoverageException


# Module-level functions.  The original API to this module was based on
# functions defined directly in the module, with a singleton of the coverage()
# class.  That design hampered programmability, so the current api uses
# explicitly-created coverage objects.  But for backward compatibility, here we
# define the top-level functions to create the singleton when they are first
# called.

# Singleton object for use with module-level functions.  The singleton is
# created as needed when one of the module-level functions is called.
_the_coverage = None

def _singleton_method(name):
    """Return a function to the `name` method on a singleton `coverage` object.

    The singleton object is created the first time one of these functions is
    called.

    """
    def wrapper(*args, **kwargs):
        """Singleton wrapper around a coverage method."""
        global _the_coverage
        if not _the_coverage:
            _the_coverage = coverage(auto_data=True)
        return getattr(_the_coverage, name)(*args, **kwargs)
    return wrapper


# Define the module-level functions.
use_cache = _singleton_method('use_cache')
start =     _singleton_method('start')
stop =      _singleton_method('stop')
erase =     _singleton_method('erase')
exclude =   _singleton_method('exclude')
analysis =  _singleton_method('analysis')
analysis2 = _singleton_method('analysis2')
report =    _singleton_method('report')
annotate =  _singleton_method('annotate')


# COPYRIGHT AND LICENSE
#
# Copyright 2001 Gareth Rees.  All rights reserved.
# Copyright 2004-2010 Ned Batchelder.  All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDERS AND CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.

# Copyright (C) 2010 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""generic routines to convert platform-specific paths to URIs."""

import atexit
import subprocess
import sys
import threading
import urllib


def abspath_to_uri(platform, path):
    """Converts a platform-specific absolute path to a file: URL."""
    return "file:" + _escape(_convert_path(platform, path))


def cygpath(path):
    """Converts an absolute cygwin path to an absolute Windows path."""
    return _CygPath.convert_using_singleton(path)


# Note that this object is not threadsafe and must only be called
# from multiple threads under protection of a lock (as is done in cygpath())
class _CygPath(object):
    """Manages a long-running 'cygpath' process for file conversion."""
    _lock = None
    _singleton = None

    @staticmethod
    def stop_cygpath_subprocess():
        if not _CygPath._lock:
            return

        with _CygPath._lock:
            if _CygPath._singleton:
                _CygPath._singleton.stop()

    @staticmethod
    def convert_using_singleton(path):
        if not _CygPath._lock:
            _CygPath._lock = threading.Lock()

        with _CygPath._lock:
            if not _CygPath._singleton:
                _CygPath._singleton = _CygPath()
                # Make sure the cygpath subprocess always gets shutdown cleanly.
                atexit.register(_CygPath.stop_cygpath_subprocess)

            return _CygPath._singleton.convert(path)

    def __init__(self):
        self._child_process = None

    def start(self):
        assert(self._child_process is None)
        args = ['cygpath', '-f', '-', '-wa']
        self._child_process = subprocess.Popen(args,
                                               stdin=subprocess.PIPE,
                                               stdout=subprocess.PIPE)

    def is_running(self):
        if not self._child_process:
            return False
        return self._child_process.returncode is None

    def stop(self):
        if self._child_process:
            self._child_process.stdin.close()
            self._child_process.wait()
        self._child_process = None

    def convert(self, path):
        if not self.is_running():
            self.start()
        self._child_process.stdin.write("%s\r\n" % path)
        self._child_process.stdin.flush()
        windows_path = self._child_process.stdout.readline().rstrip()
        # Some versions of cygpath use lowercase drive letters while others
        # use uppercase. We always convert to uppercase for consistency.
        windows_path = '%s%s' % (windows_path[0].upper(), windows_path[1:])
        return windows_path


def _escape(path):
    """Handle any characters in the path that should be escaped."""
    # FIXME: web browsers don't appear to blindly quote every character
    # when converting filenames to files. Instead of using urllib's default
    # rules, we allow a small list of other characters through un-escaped.
    # It's unclear if this is the best possible solution.
    return urllib.quote(path, safe='/+:')


def _convert_path(platform, path):
    """Handles any os-specific path separators, mappings, etc."""
    if platform.is_cygwin():
        return _winpath_to_uri(cygpath(path))
    if platform.is_win():
        return _winpath_to_uri(path)
    return _unixypath_to_uri(path)


def _winpath_to_uri(path):
    """Converts a window absolute path to a file: URL."""
    return "///" + path.replace("\\", "/")


def _unixypath_to_uri(path):
    """Converts a unix-style path to a file: URL."""
    return "//" + path

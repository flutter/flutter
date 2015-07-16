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

"""Wrapper object for the file system / source tree."""

import codecs
import errno
import exceptions
import glob
import hashlib
import os
import shutil
import sys
import tempfile
import time

class FileSystem(object):
    """FileSystem interface for webkitpy.

    Unless otherwise noted, all paths are allowed to be either absolute
    or relative."""
    sep = os.sep
    pardir = os.pardir

    def abspath(self, path):
        return os.path.abspath(path)

    def realpath(self, path):
        return os.path.realpath(path)

    def path_to_module(self, module_name):
        """A wrapper for all calls to __file__ to allow easy unit testing."""
        # FIXME: This is the only use of sys in this file. It's possible this function should move elsewhere.
        return sys.modules[module_name].__file__  # __file__ is always an absolute path.

    def expanduser(self, path):
        return os.path.expanduser(path)

    def basename(self, path):
        return os.path.basename(path)

    def chdir(self, path):
        return os.chdir(path)

    def copyfile(self, source, destination):
        shutil.copyfile(source, destination)

    def dirname(self, path):
        return os.path.dirname(path)

    def exists(self, path):
        return os.path.exists(path)

    def files_under(self, path, dirs_to_skip=[], file_filter=None):
        """Return the list of all files under the given path in topdown order.

        Args:
            dirs_to_skip: a list of directories to skip over during the
                traversal (e.g., .svn, resources, etc.)
            file_filter: if not None, the filter will be invoked
                with the filesystem object and the dirname and basename of
                each file found. The file is included in the result if the
                callback returns True.
        """
        def filter_all(fs, dirpath, basename):
            return True

        file_filter = file_filter or filter_all
        files = []
        if self.isfile(path):
            if file_filter(self, self.dirname(path), self.basename(path)):
                files.append(path)
            return files

        if self.basename(path) in dirs_to_skip:
            return []

        for (dirpath, dirnames, filenames) in os.walk(path):
            for d in dirs_to_skip:
                if d in dirnames:
                    dirnames.remove(d)

            for filename in filenames:
                if file_filter(self, dirpath, filename):
                    files.append(self.join(dirpath, filename))
        return files

    def getcwd(self):
        return os.getcwd()

    def glob(self, path):
        return glob.glob(path)

    def isabs(self, path):
        return os.path.isabs(path)

    def isfile(self, path):
        return os.path.isfile(path)

    def isdir(self, path):
        return os.path.isdir(path)

    def join(self, *comps):
        return os.path.join(*comps)

    def listdir(self, path):
        return os.listdir(path)

    def walk(self, top):
        return os.walk(top)

    def mkdtemp(self, **kwargs):
        """Create and return a uniquely named directory.

        This is like tempfile.mkdtemp, but if used in a with statement
        the directory will self-delete at the end of the block (if the
        directory is empty; non-empty directories raise errors). The
        directory can be safely deleted inside the block as well, if so
        desired.

        Note that the object returned is not a string and does not support all of the string
        methods. If you need a string, coerce the object to a string and go from there.
        """
        class TemporaryDirectory(object):
            def __init__(self, **kwargs):
                self._kwargs = kwargs
                self._directory_path = tempfile.mkdtemp(**self._kwargs)

            def __str__(self):
                return self._directory_path

            def __enter__(self):
                return self._directory_path

            def __exit__(self, type, value, traceback):
                # Only self-delete if necessary.

                # FIXME: Should we delete non-empty directories?
                if os.path.exists(self._directory_path):
                    os.rmdir(self._directory_path)

        return TemporaryDirectory(**kwargs)

    def maybe_make_directory(self, *path):
        """Create the specified directory if it doesn't already exist."""
        try:
            os.makedirs(self.join(*path))
        except OSError, e:
            if e.errno != errno.EEXIST:
                raise

    def move(self, source, destination):
        shutil.move(source, destination)

    def mtime(self, path):
        return os.stat(path).st_mtime

    def normpath(self, path):
        return os.path.normpath(path)

    def open_binary_tempfile(self, suffix):
        """Create, open, and return a binary temp file. Returns a tuple of the file and the name."""
        temp_fd, temp_name = tempfile.mkstemp(suffix)
        f = os.fdopen(temp_fd, 'wb')
        return f, temp_name

    def open_binary_file_for_reading(self, path):
        return codecs.open(path, 'rb')

    def read_binary_file(self, path):
        """Return the contents of the file at the given path as a byte string."""
        with file(path, 'rb') as f:
            return f.read()

    def write_binary_file(self, path, contents):
        with file(path, 'wb') as f:
            f.write(contents)

    def open_text_file_for_reading(self, path):
        # Note: There appears to be an issue with the returned file objects
        # not being seekable. See http://stackoverflow.com/questions/1510188/can-seek-and-tell-work-with-utf-8-encoded-documents-in-python .
        return codecs.open(path, 'r', 'utf8')

    def open_text_file_for_writing(self, path):
        return codecs.open(path, 'w', 'utf8')

    def read_text_file(self, path):
        """Return the contents of the file at the given path as a Unicode string.

        The file is read assuming it is a UTF-8 encoded file with no BOM."""
        with codecs.open(path, 'r', 'utf8') as f:
            return f.read()

    def write_text_file(self, path, contents):
        """Write the contents to the file at the given location.

        The file is written encoded as UTF-8 with no BOM."""
        with codecs.open(path, 'w', 'utf8') as f:
            f.write(contents)

    def sha1(self, path):
        contents = self.read_binary_file(path)
        return hashlib.sha1(contents).hexdigest()

    def relpath(self, path, start='.'):
        return os.path.relpath(path, start)

    class _WindowsError(exceptions.OSError):
        """Fake exception for Linux and Mac."""
        pass

    def remove(self, path, osremove=os.remove):
        """On Windows, if a process was recently killed and it held on to a
        file, the OS will hold on to the file for a short while.  This makes
        attempts to delete the file fail.  To work around that, this method
        will retry for a few seconds until Windows is done with the file."""
        try:
            exceptions.WindowsError
        except AttributeError:
            exceptions.WindowsError = FileSystem._WindowsError

        retry_timeout_sec = 3.0
        sleep_interval = 0.1
        while True:
            try:
                osremove(path)
                return True
            except exceptions.WindowsError, e:
                time.sleep(sleep_interval)
                retry_timeout_sec -= sleep_interval
                if retry_timeout_sec < 0:
                    raise e

    def rmtree(self, path):
        """Delete the directory rooted at path, whether empty or not."""
        shutil.rmtree(path, ignore_errors=True)

    def copytree(self, source, destination):
        shutil.copytree(source, destination)

    def split(self, path):
        """Return (dirname, basename + '.' + ext)"""
        return os.path.split(path)

    def splitext(self, path):
        """Return (dirname + os.sep + basename, '.' + ext)"""
        return os.path.splitext(path)

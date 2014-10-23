# Copyright (C) 2009 Google Inc. All rights reserved.
# Copyright (C) 2010 Chris Jerdonek (chris.jerdonek@gmail.com)
# Copyright (C) 2010 ProFUSION embedded systems
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

"""Supports reading and processing text files."""

import codecs
import logging
import os
import sys


_log = logging.getLogger(__name__)


class TextFileReader(object):

    """Supports reading and processing text files.

       Attributes:
         file_count: The total number of files passed to this instance
                     for processing, including non-text files and files
                     that should be skipped.
         delete_only_file_count: The total number of files that are not
                                 processed this instance actually because
                                 the files don't have any modified lines
                                 but should be treated as processed.

    """

    def __init__(self, filesystem, processor):
        """Create an instance.

        Arguments:
          processor: A ProcessorBase instance.

        """
        # FIXME: Although TextFileReader requires a FileSystem it circumvents it in two places!
        self.filesystem = filesystem
        self._processor = processor
        self.file_count = 0
        self.delete_only_file_count = 0

    def _read_lines(self, file_path):
        """Read the file at a path, and return its lines.

        Raises:
          IOError: If the file does not exist or cannot be read.

        """
        # Support the UNIX convention of using "-" for stdin.
        if file_path == '-':
            file = codecs.StreamReaderWriter(sys.stdin,
                                             codecs.getreader('utf8'),
                                             codecs.getwriter('utf8'),
                                             'replace')
        else:
            # We do not open the file with universal newline support
            # (codecs does not support it anyway), so the resulting
            # lines contain trailing "\r" characters if we are reading
            # a file with CRLF endings.
            # FIXME: This should use self.filesystem
            file = codecs.open(file_path, 'r', 'utf8', 'replace')

        try:
            contents = file.read()
        finally:
            file.close()

        lines = contents.split('\n')
        return lines

    def process_file(self, file_path, **kwargs):
        """Process the given file by calling the processor's process() method.

        Args:
          file_path: The path of the file to process.
          **kwargs: Any additional keyword parameters that should be passed
                    to the processor's process() method.  The process()
                    method should support these keyword arguments.

        Raises:
          SystemExit: If no file at file_path exists.

        """
        self.file_count += 1

        if not self.filesystem.exists(file_path) and file_path != "-":
            _log.error("File does not exist: '%s'" % file_path)
            sys.exit(1)  # FIXME: This should throw or return instead of exiting directly.

        if not self._processor.should_process(file_path):
            _log.debug("Skipping file: '%s'" % file_path)
            return
        _log.debug("Processing file: '%s'" % file_path)

        try:
            lines = self._read_lines(file_path)
        except IOError, err:
            message = ("Could not read file. Skipping: '%s'\n  %s" % (file_path, err))
            _log.warn(message)
            return

        self._processor.process(lines, file_path, **kwargs)

    def _process_directory(self, directory):
        """Process all files in the given directory, recursively."""
        # FIXME: We should consider moving to self.filesystem.files_under() (or adding walk() to FileSystem)
        for dir_path, dir_names, file_names in os.walk(directory):
            for file_name in file_names:
                file_path = self.filesystem.join(dir_path, file_name)
                self.process_file(file_path)

    def process_paths(self, paths):
        for path in paths:
            if self.filesystem.isdir(path):
                self._process_directory(directory=path)
            else:
                self.process_file(path)

    def count_delete_only_file(self):
        """Count up files that contains only deleted lines.

        Files which has no modified or newly-added lines don't need
        to check style, but should be treated as checked. For that
        purpose, we just count up the number of such files.
        """
        self.delete_only_file_count += 1

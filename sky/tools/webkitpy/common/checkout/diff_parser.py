# Copyright (C) 2009 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Google Inc. nor the names of its
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

"""WebKit's Python module for interacting with patches."""

import logging
import re

_log = logging.getLogger(__name__)


# FIXME: This is broken. We should compile our regexps up-front
# instead of using a custom cache.
_regexp_compile_cache = {}


# FIXME: This function should be removed.
def match(pattern, string):
    """Matches the string with the pattern, caching the compiled regexp."""
    if not pattern in _regexp_compile_cache:
        _regexp_compile_cache[pattern] = re.compile(pattern)
    return _regexp_compile_cache[pattern].match(string)


# FIXME: This belongs on DiffParser (e.g. as to_svn_diff()).
def git_diff_to_svn_diff(line):
    """Converts a git formatted diff line to a svn formatted line.

    Args:
      line: A string representing a line of the diff.
    """
    # FIXME: This list should be a class member on DiffParser.
    # These regexp patterns should be compiled once instead of every time.
    conversion_patterns = (("^diff --git \w/(.+) \w/(?P<FilePath>.+)", lambda matched: "Index: " + matched.group('FilePath') + "\n"),
                           ("^new file.*", lambda matched: "\n"),
                           ("^index (([0-9a-f]{7}\.\.[0-9a-f]{7})|([0-9a-f]{40}\.\.[0-9a-f]{40})) [0-9]{6}", lambda matched: "===================================================================\n"),
                           ("^--- \w/(?P<FilePath>.+)", lambda matched: "--- " + matched.group('FilePath') + "\n"),
                           ("^\+\+\+ \w/(?P<FilePath>.+)", lambda matched: "+++ " + matched.group('FilePath') + "\n"))

    for pattern, conversion in conversion_patterns:
        matched = match(pattern, line)
        if matched:
            return conversion(matched)
    return line


# This function exists so we can unittest get_diff_converter function
def svn_diff_to_svn_diff(line):
    return line


# FIXME: This method belongs on DiffParser
def get_diff_converter(lines):
    """Gets a converter function of diff lines.

    Args:
      lines: The lines of a diff file.
             If this line is git formatted, we'll return a
             converter from git to SVN.
    """
    for i, line in enumerate(lines[:-1]):
        # Stop when we find the first patch
        if line[:3] == "+++" and lines[i + 1] == "---":
            break
        if match(r"^diff --git \w/", line):
            return git_diff_to_svn_diff
    return svn_diff_to_svn_diff

_INITIAL_STATE = 1
_DECLARED_FILE_PATH = 2
_PROCESSING_CHUNK = 3


class DiffFile(object):
    """Contains the information for one file in a patch.

    The field "lines" is a list which contains tuples in this format:
       (deleted_line_number, new_line_number, line_string)
    If deleted_line_number is zero, it means this line is newly added.
    If new_line_number is zero, it means this line is deleted.
    """
    # FIXME: Tuples generally grow into classes.  We should consider
    # adding a DiffLine object.

    def added_or_modified_line_numbers(self):
        # This logic was moved from patchreader.py, but may not be
        # the right API for this object long-term.
        return [line[1] for line in self.lines if not line[0]]

    def __init__(self, filename):
        self.filename = filename
        self.lines = []

    def add_new_line(self, line_number, line):
        self.lines.append((0, line_number, line))

    def add_deleted_line(self, line_number, line):
        self.lines.append((line_number, 0, line))

    def add_unchanged_line(self, deleted_line_number, new_line_number, line):
        self.lines.append((deleted_line_number, new_line_number, line))


# If this is going to be called DiffParser, it should be a re-useable parser.
# Otherwise we should rename it to ParsedDiff or just Diff.
class DiffParser(object):
    """A parser for a patch file.

    The field "files" is a dict whose key is the filename and value is
    a DiffFile object.
    """

    def __init__(self, diff_input):
        """Parses a diff.

        Args:
          diff_input: An iterable object.
        """
        self.files = self._parse_into_diff_files(diff_input)

    # FIXME: This function is way too long and needs to be broken up.
    def _parse_into_diff_files(self, diff_input):
        files = {}
        state = _INITIAL_STATE
        current_file = None
        old_diff_line = None
        new_diff_line = None
        transform_line = get_diff_converter(diff_input)
        for line in diff_input:
            line = line.rstrip("\n")
            line = transform_line(line)

            file_declaration = match(r"^Index: (?P<FilePath>.+)", line)
            if file_declaration:
                filename = file_declaration.group('FilePath')
                current_file = DiffFile(filename)
                files[filename] = current_file
                state = _DECLARED_FILE_PATH
                continue

            lines_changed = match(r"^@@ -(?P<OldStartLine>\d+)(,\d+)? \+(?P<NewStartLine>\d+)(,\d+)? @@", line)
            if lines_changed:
                if state != _DECLARED_FILE_PATH and state != _PROCESSING_CHUNK:
                    _log.error('Unexpected line change without file path '
                               'declaration: %r' % line)
                old_diff_line = int(lines_changed.group('OldStartLine'))
                new_diff_line = int(lines_changed.group('NewStartLine'))
                state = _PROCESSING_CHUNK
                continue

            if state == _PROCESSING_CHUNK:
                if line.startswith('+'):
                    current_file.add_new_line(new_diff_line, line[1:])
                    new_diff_line += 1
                elif line.startswith('-'):
                    current_file.add_deleted_line(old_diff_line, line[1:])
                    old_diff_line += 1
                elif line.startswith(' '):
                    current_file.add_unchanged_line(old_diff_line, new_diff_line, line[1:])
                    old_diff_line += 1
                    new_diff_line += 1
                elif line == '\\ No newline at end of file':
                    # Nothing to do.  We may still have some added lines.
                    pass
                else:
                    _log.error('Unexpected diff format when parsing a '
                               'chunk: %r' % line)
        return files

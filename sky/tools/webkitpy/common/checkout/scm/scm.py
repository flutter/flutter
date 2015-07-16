# Copyright (c) 2009, Google Inc. All rights reserved.
# Copyright (c) 2009 Apple Inc. All rights reserved.
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
#
# Python module for interacting with an SCM system (like SVN or Git)

import logging
import re
import sys

from webkitpy.common.system.executive import Executive, ScriptError
from webkitpy.common.system.filesystem import FileSystem

_log = logging.getLogger(__name__)


# SCM methods are expected to return paths relative to self.checkout_root.
class SCM:
    def __init__(self, cwd, executive=None, filesystem=None):
        self.cwd = cwd
        self._executive = executive or Executive()
        self._filesystem = filesystem or FileSystem()
        self.checkout_root = self.find_checkout_root(self.cwd)

    # A wrapper used by subclasses to create processes.
    def _run(self, args, cwd=None, input=None, error_handler=None, return_exit_code=False, return_stderr=True, decode_output=True):
        # FIXME: We should set cwd appropriately.
        return self._executive.run_command(args,
                           cwd=cwd,
                           input=input,
                           error_handler=error_handler,
                           return_exit_code=return_exit_code,
                           return_stderr=return_stderr,
                           decode_output=decode_output)

    # SCM always returns repository relative path, but sometimes we need
    # absolute paths to pass to rm, etc.
    def absolute_path(self, repository_relative_path):
        return self._filesystem.join(self.checkout_root, repository_relative_path)

    def _run_status_and_extract_filenames(self, status_command, status_regexp):
        filenames = []
        # We run with cwd=self.checkout_root so that returned-paths are root-relative.
        for line in self._run(status_command, cwd=self.checkout_root).splitlines():
            match = re.search(status_regexp, line)
            if not match:
                continue
            # status = match.group('status')
            filename = match.group('filename')
            filenames.append(filename)
        return filenames

    @staticmethod
    def _subclass_must_implement():
        raise NotImplementedError("subclasses must implement")

    @classmethod
    def in_working_directory(cls, path, executive=None):
        SCM._subclass_must_implement()

    def find_checkout_root(self, path):
        SCM._subclass_must_implement()

    def add(self, path, return_exit_code=False, recurse=True):
        self.add_list([path], return_exit_code, recurse)

    def add_list(self, paths, return_exit_code=False, recurse=True):
        self._subclass_must_implement()

    def delete(self, path):
        self.delete_list([path])

    def delete_list(self, paths):
        self._subclass_must_implement()

    def move(self, origin, destination):
        self._subclass_must_implement()

    def exists(self, path):
        self._subclass_must_implement()

    def changed_files(self, git_commit=None):
        self._subclass_must_implement()

    def _added_files(self):
        self._subclass_must_implement()

    def _deleted_files(self):
        self._subclass_must_implement()

    def display_name(self):
        self._subclass_must_implement()

    def _head_svn_revision(self):
        return self.svn_revision(self.checkout_root)

    def svn_revision(self, path):
        """Returns the latest svn revision found in the checkout."""
        self._subclass_must_implement()

    def timestamp_of_revision(self, path, revision):
        self._subclass_must_implement()

    def blame(self, path):
        self._subclass_must_implement()

    def has_working_directory_changes(self):
        self._subclass_must_implement()

    #--------------------------------------------------------------------------
    # Subclasses must indicate if they support local commits,
    # but the SCM baseclass will only call local_commits methods when this is true.
    @staticmethod
    def supports_local_commits():
        SCM._subclass_must_implement()

    def commit_locally_with_message(self, message, commit_all_working_directory_changes=True):
        _log.error("Your source control manager does not support local commits.")
        sys.exit(1)

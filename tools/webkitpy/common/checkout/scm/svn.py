# Copyright (c) 2009, 2010, 2011 Google Inc. All rights reserved.
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

import logging
import os
import random
import re
import shutil
import string
import sys
import tempfile

from webkitpy.common.memoized import memoized
from webkitpy.common.system.executive import Executive, ScriptError

from .scm import SCM

_log = logging.getLogger(__name__)


class SVN(SCM):

    executable_name = "svn"

    _svn_metadata_files = frozenset(['.svn', '_svn'])

    def __init__(self, cwd, patch_directories, **kwargs):
        SCM.__init__(self, cwd, **kwargs)
        self._bogus_dir = None
        if patch_directories == []:
            raise Exception(message='Empty list of patch directories passed to SCM.__init__')
        elif patch_directories == None:
            self._patch_directories = [self._filesystem.relpath(cwd, self.checkout_root)]
        else:
            self._patch_directories = patch_directories

    @classmethod
    def in_working_directory(cls, path, executive=None):
        if os.path.isdir(os.path.join(path, '.svn')):
            # This is a fast shortcut for svn info that is usually correct for SVN < 1.7,
            # but doesn't work for SVN >= 1.7.
            return True

        executive = executive or Executive()
        svn_info_args = [cls.executable_name, 'info']
        exit_code = executive.run_command(svn_info_args, cwd=path, return_exit_code=True)
        return (exit_code == 0)

    def _find_uuid(self, path):
        if not self.in_working_directory(path):
            return None
        return self.value_from_svn_info(path, 'Repository UUID')

    @classmethod
    def value_from_svn_info(cls, path, field_name):
        svn_info_args = [cls.executable_name, 'info']
        # FIXME: This method should use a passed in executive or be made an instance method and use self._executive.
        info_output = Executive().run_command(svn_info_args, cwd=path).rstrip()
        match = re.search("^%s: (?P<value>.+)$" % field_name, info_output, re.MULTILINE)
        if not match:
            raise ScriptError(script_args=svn_info_args, message='svn info did not contain a %s.' % field_name)
        return match.group('value').rstrip('\r')

    def find_checkout_root(self, path):
        uuid = self._find_uuid(path)
        # If |path| is not in a working directory, we're supposed to return |path|.
        if not uuid:
            return path
        # Search up the directory hierarchy until we find a different UUID.
        last_path = None
        while True:
            if uuid != self._find_uuid(path):
                return last_path
            last_path = path
            (path, last_component) = self._filesystem.split(path)
            if last_path == path:
                return None

    def _run_svn(self, args, **kwargs):
        return self._run([self.executable_name] + args, **kwargs)

    @memoized
    def _svn_version(self):
        return self._run_svn(['--version', '--quiet'])

    def has_working_directory_changes(self):
        # FIXME: What about files which are not committed yet?
        return self._run_svn(["diff"], cwd=self.checkout_root, decode_output=False) != ""

    def status_command(self):
        return [self.executable_name, 'status']

    def _status_regexp(self, expected_types):
        field_count = 6 if self._svn_version() > "1.6" else 5
        return "^(?P<status>[%s]).{%s} (?P<filename>.+)$" % (expected_types, field_count)

    def _add_parent_directories(self, path, recurse):
        """Does 'svn add' to the path and its parents."""
        if self.in_working_directory(path):
            return
        self.add(path, recurse=recurse)

    def add_list(self, paths, return_exit_code=False, recurse=True):
        for path in paths:
            self._add_parent_directories(os.path.dirname(os.path.abspath(path)),
                                         recurse=False)
        if recurse:
            cmd = ["add"] + paths
        else:
            cmd = ["add", "--depth", "empty"] + paths
        return self._run_svn(cmd, return_exit_code=return_exit_code)

    def _delete_parent_directories(self, path):
        if not self.in_working_directory(path):
            return
        if set(os.listdir(path)) - self._svn_metadata_files:
            return  # Directory has non-trivial files in it.
        self.delete(path)

    def delete_list(self, paths):
        for path in paths:
            abs_path = os.path.abspath(path)
            parent, base = os.path.split(abs_path)
            result = self._run_svn(["delete", "--force", base], cwd=parent)
            self._delete_parent_directories(os.path.dirname(abs_path))
        return result

    def move(self, origin, destination):
        return self._run_svn(["mv", "--force", origin, destination], return_exit_code=True)

    def exists(self, path):
        return not self._run_svn(["info", path], return_exit_code=True, decode_output=False)

    def changed_files(self, git_commit=None):
        status_command = [self.executable_name, "status"]
        status_command.extend(self._patch_directories)
        # ACDMR: Addded, Conflicted, Deleted, Modified or Replaced
        return self._run_status_and_extract_filenames(status_command, self._status_regexp("ACDMR"))

    def _added_files(self):
        return self._run_status_and_extract_filenames(self.status_command(), self._status_regexp("A"))

    def _deleted_files(self):
        return self._run_status_and_extract_filenames(self.status_command(), self._status_regexp("D"))

    @staticmethod
    def supports_local_commits():
        return False

    def display_name(self):
        return "svn"

    def svn_revision(self, path):
        return self.value_from_svn_info(path, 'Revision')

    def timestamp_of_revision(self, path, revision):
        # We use --xml to get timestamps like 2013-02-08T08:18:04.964409Z
        repository_root = self.value_from_svn_info(self.checkout_root, 'Repository Root')
        info_output = Executive().run_command([self.executable_name, 'log', '-r', revision, '--xml', repository_root], cwd=path).rstrip()
        match = re.search(r"^<date>(?P<value>.+)</date>\r?$", info_output, re.MULTILINE)
        return match.group('value')

    def create_patch(self, git_commit=None, changed_files=None):
        """Returns a byte array (str()) representing the patch file.
        Patch files are effectively binary since they may contain
        files of multiple different encodings."""
        if changed_files == []:
            return ""
        elif changed_files == None:
            changed_files = []
        return self._run([self._filesystem.join(self.checkout_root, 'Tools', 'Scripts', 'svn-create-patch')] + changed_files,
            cwd=self.checkout_root, return_stderr=False,
            decode_output=False)

    def blame(self, path):
        return self._run_svn(['blame', path])

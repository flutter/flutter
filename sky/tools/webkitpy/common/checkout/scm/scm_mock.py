# Copyright (C) 2011 Google Inc. All rights reserved.
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

from webkitpy.common.system.filesystem_mock import MockFileSystem
from webkitpy.common.system.executive_mock import MockExecutive


class MockSCM(object):
    executable_name = "MockSCM"

    def __init__(self, filesystem=None, executive=None):
        self.checkout_root = "/mock-checkout/third_party/WebKit"
        self.added_paths = set()
        self._filesystem = filesystem or MockFileSystem()
        self._executive = executive or MockExecutive()

    def add(self, destination_path, return_exit_code=False):
        self.add_list([destination_path], return_exit_code)

    def add_list(self, destination_paths, return_exit_code=False):
        self.added_paths.update(set(destination_paths))
        if return_exit_code:
            return 0

    def has_working_directory_changes(self):
        return False

    def ensure_cleanly_tracking_remote_master(self):
        pass

    def current_branch(self):
        return "mock-branch-name"

    def checkout_branch(self, name):
        pass

    def create_clean_branch(self, name):
        pass

    def delete_branch(self, name):
        pass

    def supports_local_commits(self):
        return True

    def exists(self, path):
        # TestRealMain.test_real_main (and several other rebaseline tests) are sensitive to this return value.
        # We should make those tests more robust, but for now we just return True always (since no test needs otherwise).
        return True

    def absolute_path(self, *comps):
        return self._filesystem.join(self.checkout_root, *comps)

    def svn_revision(self, path):
        return '5678'

    def svn_revision_from_git_commit(self, git_commit):
        if git_commit == '6469e754a1':
            return 1234
        if git_commit == '624c3081c0':
            return 5678
        if git_commit == '624caaaaaa':
            return 10000
        return None

    def timestamp_of_revision(self, path, revision):
        return '2013-02-01 08:48:05 +0000'

    def commit_locally_with_message(self, message, commit_all_working_directory_changes=True):
        pass

    def delete(self, path):
        return self.delete_list([path])

    def delete_list(self, paths):
        if not self._filesystem:
            return
        for path in paths:
            if self._filesystem.exists(path):
                self._filesystem.remove(path)

    def move(self, origin, destination):
        if self._filesystem:
            self._filesystem.move(self.absolute_path(origin), self.absolute_path(destination))

    def changed_files(self):
        return []

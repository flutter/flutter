# Copyright (c) 2011 Google Inc. All rights reserved.
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

from StringIO import StringIO

from webkitpy.common.system.environment import Environment
from webkitpy.common.system.executive_mock import MockExecutive
from webkitpy.common.system.filesystem_mock import MockFileSystem
from webkitpy.common.system.platforminfo_mock import MockPlatformInfo
from webkitpy.common.system.user_mock import MockUser
from webkitpy.common.system.workspace_mock import MockWorkspace


class MockSystemHost(object):
    def __init__(self, log_executive=False, executive_throws_when_run=None, os_name=None, os_version=None, executive=None, filesystem=None):
        self.executable = 'python'
        self.executive = executive or MockExecutive(should_log=log_executive, should_throw_when_run=executive_throws_when_run)
        self.filesystem = filesystem or MockFileSystem()
        self.user = MockUser()
        self.platform = MockPlatformInfo()
        if os_name:
            self.platform.os_name = os_name
        if os_version:
            self.platform.os_version = os_version

        # FIXME: Should this take pointers to the filesystem and the executive?
        self.workspace = MockWorkspace()

        self.stdout = StringIO()
        self.stderr = StringIO()

    def copy_current_environment(self):
        return Environment({"MOCK_ENVIRON_COPY": '1'})

    def print_(self, *args, **kwargs):
        sep = kwargs.get('sep', ' ')
        end = kwargs.get('end', '\n')
        file = kwargs.get('file', None)
        stderr = kwargs.get('stderr', False)

        file = file or (self.stderr if stderr else self.stdout)
        file.write(sep.join([str(arg) for arg in args]) + end)

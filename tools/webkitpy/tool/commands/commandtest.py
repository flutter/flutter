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

import unittest

from webkitpy.common.system.outputcapture import OutputCapture
from webkitpy.tool.mocktool import MockOptions, MockTool


class CommandsTest(unittest.TestCase):
    def assert_execute_outputs(self, command, args=[], expected_stdout="", expected_stderr="", expected_exception=None, expected_logs=None, options=MockOptions(), tool=MockTool()):
        options.blocks = None
        options.cc = 'MOCK cc'
        options.component = 'MOCK component'
        options.confirm = True
        options.email = 'MOCK email'
        options.git_commit = 'MOCK git commit'
        options.obsolete_patches = True
        options.open_bug = True
        options.port = 'MOCK port'
        options.update_changelogs = False
        options.quiet = True
        options.reviewer = 'MOCK reviewer'
        command.bind_to_tool(tool)
        OutputCapture().assert_outputs(self, command.execute, [options, args, tool], expected_stdout=expected_stdout, expected_stderr=expected_stderr, expected_exception=expected_exception, expected_logs=expected_logs)

# Copyright (C) 2013 Google Inc. All rights reserved.
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

import unittest

from webkitpy.common.host_mock import MockHost
from webkitpy.layout_tests.print_layout_test_types import main


class PrintLayoutTestTimesTest(unittest.TestCase):

    def check(self, args, expected_output, files=None):
        host = MockHost()
        files = files or {}
        for path, contents in files.items():
            host.filesystem.write_binary_file(path, contents)
        orig_get = host.port_factory.get
        host.port_factory.get = lambda *args, **kwargs: orig_get('test')
        main(host, args)
        self.assertEqual(host.stdout.getvalue(), expected_output)

    def test_test_list(self):
        files = {'/tmp/test_list': 'passes/image.html'}
        self.check(['--test-list', '/tmp/test_list'], 'passes/image.html pixel\n', files=files)

    def test_type(self):
        self.check(['--type', 'audio', 'passes'], 'passes/audio.html\n')

    def test_basic(self):
        self.check(['failures/unexpected/missing_image.html', 'passes/image.html', 'passes/audio.html', 'passes/reftest.html'],
            'failures/unexpected/missing_image.html text\n'
            'passes/image.html pixel\n'
            'passes/audio.html audio\n'
            'passes/reftest.html ref\n')

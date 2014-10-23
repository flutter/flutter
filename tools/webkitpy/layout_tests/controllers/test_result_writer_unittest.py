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

import optparse
import unittest

from webkitpy.common.system.systemhost_mock import MockSystemHost
from webkitpy.layout_tests.controllers.test_result_writer import write_test_result
from webkitpy.layout_tests.port.driver import DriverOutput
from webkitpy.layout_tests.port.test import TestPort
from webkitpy.layout_tests.models import test_failures


class TestResultWriterTests(unittest.TestCase):
    def run_test(self, failures=None, files=None):
        failures = failures or []
        host = MockSystemHost()
        host.filesystem.files = files or {}
        port = TestPort(host=host, port_name='test-mac-snowleopard', options=optparse.Values())
        actual_output = DriverOutput(text='', image=None, image_hash=None, audio=None)
        expected_output = DriverOutput(text='', image=None, image_hash=None, audio=None)
        write_test_result(host.filesystem, port, '/tmp', 'foo.html', actual_output, expected_output, failures)
        return host.filesystem.written_files

    def test_success(self):
        # Nothing is written when the test passes.
        written_files = self.run_test(failures=[])
        self.assertEqual(written_files, {})

    def test_reference_exists(self):
        failure = test_failures.FailureReftestMismatch()
        failure.reference_filename = '/src/exists-expected.html'
        files = {'/src/exists-expected.html': 'yup'}
        written_files = self.run_test(failures=[failure], files=files)
        self.assertEqual(written_files, {'/tmp/exists-expected.html': 'yup'})

        failure = test_failures.FailureReftestMismatchDidNotOccur()
        failure.reference_filename = '/src/exists-expected-mismatch.html'
        files = {'/src/exists-expected-mismatch.html': 'yup'}
        written_files = self.run_test(failures=[failure], files=files)
        self.assertEqual(written_files, {'/tmp/exists-expected-mismatch.html': 'yup'})

    def test_reference_is_missing(self):
        failure = test_failures.FailureReftestMismatch()
        failure.reference_filename = 'notfound.html'
        written_files = self.run_test(failures=[failure], files={})
        self.assertEqual(written_files, {})

        failure = test_failures.FailureReftestMismatchDidNotOccur()
        failure.reference_filename = 'notfound.html'
        written_files = self.run_test(failures=[failure], files={})
        self.assertEqual(written_files, {})

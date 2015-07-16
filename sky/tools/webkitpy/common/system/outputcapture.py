# Copyright (c) 2009, Google Inc. All rights reserved.
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
# Class for unittest support.  Used for capturing stderr/stdout.

import logging
import sys
import unittest

from StringIO import StringIO


class OutputCapture(object):
    # By default we capture the output to a stream. Other modules may override
    # this function in order to do things like pass through the output. See
    # webkitpy.test.main for an example.
    @staticmethod
    def stream_wrapper(stream):
        return StringIO()

    def __init__(self):
        self.saved_outputs = dict()
        self._log_level = logging.INFO

    def set_log_level(self, log_level):
        self._log_level = log_level
        if hasattr(self, '_logs_handler'):
            self._logs_handler.setLevel(self._log_level)

    def _capture_output_with_name(self, output_name):
        stream = getattr(sys, output_name)
        captured_output = self.stream_wrapper(stream)
        self.saved_outputs[output_name] = stream
        setattr(sys, output_name, captured_output)
        return captured_output

    def _restore_output_with_name(self, output_name):
        captured_output = getattr(sys, output_name).getvalue()
        setattr(sys, output_name, self.saved_outputs[output_name])
        del self.saved_outputs[output_name]
        return captured_output

    def capture_output(self):
        self._logs = StringIO()
        self._logs_handler = logging.StreamHandler(self._logs)
        self._logs_handler.setLevel(self._log_level)
        self._logger = logging.getLogger()
        self._orig_log_level = self._logger.level
        self._logger.addHandler(self._logs_handler)
        self._logger.setLevel(min(self._log_level, self._orig_log_level))
        return (self._capture_output_with_name("stdout"), self._capture_output_with_name("stderr"))

    def restore_output(self):
        self._logger.removeHandler(self._logs_handler)
        self._logger.setLevel(self._orig_log_level)
        self._logs_handler.flush()
        self._logs.flush()
        logs_string = self._logs.getvalue()
        delattr(self, '_logs_handler')
        delattr(self, '_logs')
        return (self._restore_output_with_name("stdout"), self._restore_output_with_name("stderr"), logs_string)

    def assert_outputs(self, testcase, function, args=[], kwargs={}, expected_stdout="", expected_stderr="", expected_exception=None, expected_logs=None):
        self.capture_output()
        try:
            if expected_exception:
                return_value = testcase.assertRaises(expected_exception, function, *args, **kwargs)
            else:
                return_value = function(*args, **kwargs)
        finally:
            (stdout_string, stderr_string, logs_string) = self.restore_output()

        if hasattr(testcase, 'assertMultiLineEqual'):
            testassert = testcase.assertMultiLineEqual
        else:
            testassert = testcase.assertEqual

        testassert(stdout_string, expected_stdout)
        testassert(stderr_string, expected_stderr)
        if expected_logs is not None:
            testassert(logs_string, expected_logs)
        # This is a little strange, but I don't know where else to return this information.
        return return_value


class OutputCaptureTestCaseBase(unittest.TestCase):
    maxDiff = None

    def setUp(self):
        unittest.TestCase.setUp(self)
        self.output_capture = OutputCapture()
        (self.__captured_stdout, self.__captured_stderr) = self.output_capture.capture_output()

    def tearDown(self):
        del self.__captured_stdout
        del self.__captured_stderr
        self.output_capture.restore_output()
        unittest.TestCase.tearDown(self)

    def assertStdout(self, expected_stdout):
        self.assertEqual(expected_stdout, self.__captured_stdout.getvalue())

    def assertStderr(self, expected_stderr):
        self.assertEqual(expected_stderr, self.__captured_stderr.getvalue())

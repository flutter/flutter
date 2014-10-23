# Copyright (C) 2011 Apple Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import logging
import unittest

from webkitpy.common.system.outputcapture import OutputCapture


_log = logging.getLogger(__name__)


class OutputCaptureTest(unittest.TestCase):
    def setUp(self):
        self.output = OutputCapture()

    def log_all_levels(self):
        _log.info('INFO')
        _log.warning('WARN')
        _log.error('ERROR')
        _log.critical('CRITICAL')

    def assertLogged(self, expected_logs):
        actual_stdout, actual_stderr, actual_logs = self.output.restore_output()
        self.assertEqual('', actual_stdout)
        self.assertEqual('', actual_stderr)
        self.assertMultiLineEqual(expected_logs, actual_logs)

    def test_initial_log_level(self):
        self.output.capture_output()
        self.log_all_levels()
        self.assertLogged('INFO\nWARN\nERROR\nCRITICAL\n')

    def test_set_log_level(self):
        self.output.set_log_level(logging.ERROR)
        self.output.capture_output()
        self.log_all_levels()
        self.output.set_log_level(logging.WARN)
        self.log_all_levels()
        self.assertLogged('ERROR\nCRITICAL\nWARN\nERROR\nCRITICAL\n')

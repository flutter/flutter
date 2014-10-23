# Copyright (C) 2012 Google, Inc.
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

import StringIO
import logging
import sys
import unittest

from webkitpy.common.system.filesystem import FileSystem
from webkitpy.common.system.executive import Executive
from webkitpy.common.system.outputcapture import OutputCapture
from webkitpy.test.main import Tester


STUBS_CLASS = __name__ + ".TestStubs"


class TestStubs(unittest.TestCase):
    def test_empty(self):
        pass


class TesterTest(unittest.TestCase):

    def test_no_tests_found(self):
        tester = Tester()
        errors = StringIO.StringIO()

        # Here we need to remove any existing log handlers so that they
        # don't log the messages webkitpy.test while we're testing it.
        root_logger = logging.getLogger()
        root_handlers = root_logger.handlers
        root_logger.handlers = []

        tester.printer.stream = errors
        tester.finder.find_names = lambda args, run_all: []
        oc = OutputCapture()
        orig_argv = sys.argv[:]
        try:
            sys.argv = sys.argv[0:1]
            oc.capture_output()
            self.assertFalse(tester.run())
        finally:
            _, _, logs = oc.restore_output()
            root_logger.handlers = root_handlers
            sys.argv = orig_argv

        self.assertIn('No tests to run', errors.getvalue())
        self.assertIn('No tests to run', logs)

    def _find_test_names(self, args):
        tester = Tester()
        tester._options, args = tester._parse_args(args)
        return tester._test_names(unittest.TestLoader(), args)

    def test_individual_names_are_not_run_twice(self):
        args = [STUBS_CLASS + '.test_empty']
        tests = self._find_test_names(args)
        self.assertEqual(tests, args)

    def test_coverage_works(self):
        # This is awkward; by design, running test-webkitpy -c will
        # create a .coverage file in Tools/Scripts, so we need to be
        # careful not to clobber an existing one, and to clean up.
        # FIXME: This design needs to change since it means we can't actually
        # run this method itself under coverage properly.
        filesystem = FileSystem()
        executive = Executive()
        module_path = filesystem.path_to_module(self.__module__)
        script_dir = module_path[0:module_path.find('webkitpy') - 1]
        coverage_file = filesystem.join(script_dir, '.coverage')
        coverage_file_orig = None
        if filesystem.exists(coverage_file):
            coverage_file_orig = coverage_file + '.orig'
            filesystem.move(coverage_file, coverage_file_orig)

        try:
            proc = executive.popen([sys.executable, filesystem.join(script_dir, 'test-webkitpy'), '-c', STUBS_CLASS + '.test_empty'],
                                stdout=executive.PIPE, stderr=executive.PIPE)
            out, _ = proc.communicate()
            retcode = proc.returncode
            self.assertEqual(retcode, 0)
            self.assertIn('Cover', out)
        finally:
            if coverage_file_orig:
                filesystem.move(coverage_file_orig, coverage_file)
            elif filesystem.exists(coverage_file):
                filesystem.remove(coverage_file)

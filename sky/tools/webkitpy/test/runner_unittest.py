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
import re
import unittest

from webkitpy.common.system.filesystem import FileSystem
from webkitpy.common.webkit_finder import WebKitFinder

from webkitpy.tool.mocktool import MockOptions
from webkitpy.test.printer import Printer
from webkitpy.test.runner import Runner


class FakeModuleSuite(object):
    def __init__(self, name, result, msg):
        self.name = name
        self.result = result
        self.msg = msg

    def __str__(self):
        return self.name

    def run(self, result):
        result.testsRun += 1
        if self.result == 'F':
            result.failures.append((self.name, self.msg))
        elif self.result == 'E':
            result.errors.append((self.name, self.msg))


class FakeTopSuite(object):
    def __init__(self, tests):
        self._tests = tests


class FakeLoader(object):
    def __init__(self, *test_triples):
        self.triples = test_triples
        self._tests = []
        self._results = {}
        for test_name, result, msg in self.triples:
            self._tests.append(test_name)
            m = re.match("(\w+) \(([\w.]+)\)", test_name)
            self._results['%s.%s' % (m.group(2), m.group(1))] = tuple([test_name, result, msg])

    def top_suite(self):
        return FakeTopSuite(self._tests)

    def loadTestsFromName(self, name, _):
        return FakeModuleSuite(*self._results[name])


class RunnerTest(unittest.TestCase):
    def setUp(self):
        # Here we have to jump through a hoop to make sure test-webkitpy doesn't log
        # any messages from these tests :(.
        self.root_logger = logging.getLogger()
        self.log_levels = []
        self.log_handlers = self.root_logger.handlers[:]
        for handler in self.log_handlers:
            self.log_levels.append(handler.level)
            handler.level = logging.CRITICAL

    def tearDown(self):
        for handler in self.log_handlers:
            handler.level = self.log_levels.pop(0)

    def test_run(self, verbose=0, timing=False, child_processes=1, quiet=False):
        options = MockOptions(verbose=verbose, timing=timing, child_processes=child_processes, quiet=quiet, pass_through=False)
        stream = StringIO.StringIO()
        loader = FakeLoader(('test1 (Foo)', '.', ''),
                            ('test2 (Foo)', 'F', 'test2\nfailed'),
                            ('test3 (Foo)', 'E', 'test3\nerred'))
        runner = Runner(Printer(stream, options), loader, WebKitFinder(FileSystem()))
        runner.run(['Foo.test1', 'Foo.test2', 'Foo.test3'], 1)
        self.assertEqual(runner.tests_run, 3)
        self.assertEqual(len(runner.failures), 1)
        self.assertEqual(len(runner.errors), 1)

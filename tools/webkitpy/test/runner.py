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

"""code to actually run a list of python tests."""

import re
import sys
import time
import unittest

from webkitpy.common import message_pool

_test_description = re.compile("(\w+) \(([\w.]+)\)")


def unit_test_name(test):
    m = _test_description.match(str(test))
    return "%s.%s" % (m.group(2), m.group(1))


class Runner(object):
    def __init__(self, printer, loader, webkit_finder):
        self.printer = printer
        self.loader = loader
        self.webkit_finder = webkit_finder
        self.tests_run = 0
        self.errors = []
        self.failures = []
        self.worker_factory = lambda caller: _Worker(caller, self.loader, self.webkit_finder)

    def run(self, test_names, num_workers):
        if not test_names:
            return
        num_workers = min(num_workers, len(test_names))
        with message_pool.get(self, self.worker_factory, num_workers) as pool:
            pool.run(('test', test_name) for test_name in test_names)

    def handle(self, message_name, source, test_name, delay=None, failures=None, errors=None):
        if message_name == 'started_test':
            self.printer.print_started_test(source, test_name)
            return

        self.tests_run += 1
        if failures:
            self.failures.append((test_name, failures))
        if errors:
            self.errors.append((test_name, errors))
        self.printer.print_finished_test(source, test_name, delay, failures, errors)


class _Worker(object):
    def __init__(self, caller, loader, webkit_finder):
        self._caller = caller
        self._loader = loader

        # FIXME: coverage needs to be in sys.path for its internal imports to work.
        thirdparty_path = webkit_finder.path_from_webkit_base('Tools', 'Scripts', 'webkitpy', 'thirdparty')
        if not thirdparty_path in sys.path:
            sys.path.append(thirdparty_path)


    def handle(self, message_name, source, test_name):
        assert message_name == 'test'
        result = unittest.TestResult()
        start = time.time()
        self._caller.post('started_test', test_name)

        # We will need to rework this if a test_name results in multiple tests.
        self._loader.loadTestsFromName(test_name, None).run(result)
        self._caller.post('finished_test', test_name, time.time() - start,
            [failure[1] for failure in result.failures], [error[1] for error in result.errors])

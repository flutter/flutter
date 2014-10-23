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

import logging
import math
import optparse
import os
import subprocess
import sys

from webkitpy.common.system.executive import Executive
from webkitpy.common.system.filesystem import FileSystem
from webkitpy.common.webkit_finder import WebKitFinder

_log = logging.getLogger(__name__)


class Bucket(object):
    def __init__(self, tests):
        self.tests = tests

    def size(self):
        return len(self.tests)


class Bisector(object):

    def __init__(self, tests, is_debug):
        self.executive = Executive()
        self.tests = tests
        self.expected_failure = tests[-1]
        self.is_debug = is_debug
        self.webkit_finder = WebKitFinder(FileSystem())

    def bisect(self):
        if self.test_fails_in_isolation():
            self.buckets = [Bucket([self.expected_failure])]
            print '%s fails when run in isolation.' % self.expected_failure
            self.print_result()
            return 0
        if not self.test_fails(self.tests):
            _log.error('%s does not fail' % self.expected_failure)
            return 1
        # Split the list of test into buckets. Each bucket has at least one test required to cause
        # the expected failure at the end. Split buckets in half until there are only buckets left
        # with one item in them.
        self.buckets = [Bucket(self.tests[:-1]), Bucket([self.expected_failure])]
        while not self.is_done():
            self.print_progress()
            self.split_largest_bucket()
        self.print_result()
        self.verify_non_flaky()
        return 0

    def test_fails_in_isolation(self):
        return self.test_bucket_list_fails([Bucket([self.expected_failure])])

    def verify_non_flaky(self):
        print 'Verifying the failure is not flaky by running 10 times.'
        count_failures = 0
        for i in range(0, 10):
            if self.test_bucket_list_fails(self.buckets):
                count_failures += 1
        print 'Failed %d/10 times' % count_failures

    def print_progress(self):
        count = 0
        for bucket in self.buckets:
            count += len(bucket.tests)
        print '%d tests left, %d buckets' % (count, len(self.buckets))

    def print_result(self):
        tests = []
        for bucket in self.buckets:
            tests += bucket.tests
        extra_args = ' --debug' if self.is_debug else ''
        print 'run-webkit-tests%s --child-processes=1 --order=none %s' % (extra_args, " ".join(tests))

    def is_done(self):
        for bucket in self.buckets:
            if bucket.size() > 1:
                return False
        return True

    def split_largest_bucket(self):
        index = 0
        largest_index = 0
        largest_size = 0
        for bucket in self.buckets:
            if bucket.size() > largest_size:
                largest_index = index
                largest_size = bucket.size()
            index += 1

        bucket_to_split = self.buckets[largest_index]
        halfway_point = int(largest_size / 2)
        first_half = Bucket(bucket_to_split.tests[:halfway_point])
        second_half = Bucket(bucket_to_split.tests[halfway_point:])

        buckets_before = self.buckets[:largest_index]
        buckets_after = self.buckets[largest_index + 1:]

        # Do the second half first because it tends to be faster because the http tests are front-loaded and slow.
        new_buckets = buckets_before + [second_half] + buckets_after
        if self.test_bucket_list_fails(new_buckets):
            self.buckets = new_buckets
            return

        new_buckets = buckets_before + [first_half] + buckets_after
        if self.test_bucket_list_fails(new_buckets):
            self.buckets = new_buckets
            return

        self.buckets = buckets_before + [first_half, second_half] + buckets_after

    def test_bucket_list_fails(self, buckets):
        tests = []
        for bucket in buckets:
            tests += bucket.tests
        return self.test_fails(tests)

    def test_fails(self, tests):
        extra_args = ['--debug'] if self.is_debug else []
        path_to_run_webkit_tests = self.webkit_finder.path_from_webkit_base('Tools', 'Scripts', 'run-webkit-tests')
        output = self.executive.popen([path_to_run_webkit_tests, '--child-processes', '1', '--order', 'none', '--no-retry', '--no-show-results', '--verbose'] + extra_args + tests, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        failure_string = self.expected_failure + ' failed'
        if failure_string in output.stderr.read():
            return True
        return False


def main(argv):
    logging.basicConfig()

    option_parser = optparse.OptionParser()
    option_parser.add_option('--test-list', action='store', help='file that list tests to bisect. The last test in the list is the expected failure.', metavar='FILE'),
    option_parser.add_option('--debug', action='store_true', default=False, help='whether to use a debug build'),
    options, args = option_parser.parse_args(argv)

    tests = open(options.test_list).read().strip().split('\n')
    bisector = Bisector(tests, is_debug=options.debug)
    return bisector.bisect()

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

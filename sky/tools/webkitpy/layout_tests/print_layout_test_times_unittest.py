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
from webkitpy.layout_tests.print_layout_test_times import main


class PrintLayoutTestTimesTest(unittest.TestCase):

    def check(self, args, expected_output, files=None):
        host = MockHost()
        fs = host.filesystem
        results_directory = host.port_factory.get().results_directory()
        if files:
            fs.files = files
        else:
            fs.write_text_file(fs.join(results_directory, 'times_ms.json'), """
                {"foo": {"foo1": {"fast1.html": 10,
                                  "fast2.html": 10,
                                  "slow1.html": 80},
                         "foo2": {"fast3.html": 10,
                                  "fast4.html": 10,
                                  "slow2.html": 80}},
                 "bar": {"bar1": {"fast5.html": 10,
                                  "fast6.html": 10,
                                  "slow3.html": 80}}}
                """)
        main(host, args)
        self.assertEqual(host.stdout.getvalue(), expected_output)

    def test_fastest_overall(self):
        # This is the fastest 10% of the tests overall (ignoring dir structure, equivalent to -f 0).
        self.check(['--fastest', '10'],
            "bar/bar1/fast5.html 10\n"
            "bar/bar1/fast6.html 10\n"
            "foo/foo1/fast1.html 10\n")

    def test_fastest_forward_1(self):
        # Note that we don't get anything from foo/foo2, as foo/foo1 used up the budget for foo.
        self.check(['-f', '1', '--fastest', '10'],
            "bar/bar1/fast5.html 10\n"
            "foo/foo1/fast1.html 10\n"
            "foo/foo1/fast2.html 10\n")

    def test_fastest_back_1(self):
        # Here we get one test from each dir, showing that we are going properly breadth-first.
        self.check(['-b', '1', '--fastest', '10'],
            "bar/bar1/fast5.html 10\n"
            "foo/foo1/fast1.html 10\n"
            "foo/foo2/fast3.html 10\n")

    def test_no_args(self):
        # This should be every test, sorted lexicographically.
        self.check([],
            "bar/bar1/fast5.html 10\n"
            "bar/bar1/fast6.html 10\n"
            "bar/bar1/slow3.html 80\n"
            "foo/foo1/fast1.html 10\n"
            "foo/foo1/fast2.html 10\n"
            "foo/foo1/slow1.html 80\n"
            "foo/foo2/fast3.html 10\n"
            "foo/foo2/fast4.html 10\n"
            "foo/foo2/slow2.html 80\n")

    def test_total(self):
        self.check(['-f', '0'], "300\n")

    def test_forward_one(self):
        self.check(['-f', '1'],
                   "bar 100\n"
                   "foo 200\n")

    def test_backward_one(self):
        self.check(['-b', '1'],
                   "bar/bar1 100\n"
                   "foo/foo1 100\n"
                   "foo/foo2 100\n")

    def test_path_to_file(self):
        # Tests that we can use a custom file rather than the port's default.
        self.check(['/tmp/times_ms.json'], "foo/bar.html 1\n",
                   files={'/tmp/times_ms.json': '{"foo":{"bar.html": 1}}'})

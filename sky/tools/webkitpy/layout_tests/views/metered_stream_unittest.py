# Copyright (C) 2010, 2012 Google Inc. All rights reserved.
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

import StringIO
import logging
import re
import unittest

from webkitpy.layout_tests.views.metered_stream import MeteredStream


class RegularTest(unittest.TestCase):
    verbose = False
    isatty = False

    def setUp(self):
        self.stream = StringIO.StringIO()
        self.buflist = self.stream.buflist
        self.stream.isatty = lambda: self.isatty

        # configure a logger to test that log calls do normally get included.
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.DEBUG)
        self.logger.propagate = False

        # add a dummy time counter for a default behavior.
        self.times = range(10)

        self.meter = MeteredStream(self.stream, self.verbose, self.logger, self.time_fn, 8675)

    def tearDown(self):
        if self.meter:
            self.meter.cleanup()
            self.meter = None

    def time_fn(self):
        return self.times.pop(0)

    def test_logging_not_included(self):
        # This tests that if we don't hand a logger to the MeteredStream,
        # nothing is logged.
        logging_stream = StringIO.StringIO()
        handler = logging.StreamHandler(logging_stream)
        root_logger = logging.getLogger()
        orig_level = root_logger.level
        root_logger.addHandler(handler)
        root_logger.setLevel(logging.DEBUG)
        try:
            self.meter = MeteredStream(self.stream, self.verbose, None, self.time_fn, 8675)
            self.meter.write_throttled_update('foo')
            self.meter.write_update('bar')
            self.meter.write('baz')
            self.assertEqual(logging_stream.buflist, [])
        finally:
            root_logger.removeHandler(handler)
            root_logger.setLevel(orig_level)

    def _basic(self, times):
        self.times = times
        self.meter.write_update('foo')
        self.meter.write_update('bar')
        self.meter.write_throttled_update('baz')
        self.meter.write_throttled_update('baz 2')
        self.meter.writeln('done')
        self.assertEqual(self.times, [])
        return self.buflist

    def test_basic(self):
        buflist = self._basic([0, 1, 2, 13, 14])
        self.assertEqual(buflist, ['foo\n', 'bar\n', 'baz 2\n', 'done\n'])

    def _log_after_update(self):
        self.meter.write_update('foo')
        self.logger.info('bar')
        return self.buflist

    def test_log_after_update(self):
        buflist = self._log_after_update()
        self.assertEqual(buflist, ['foo\n', 'bar\n'])

    def test_log_args(self):
        self.logger.info('foo %s %d', 'bar', 2)
        self.assertEqual(self.buflist, ['foo bar 2\n'])

class TtyTest(RegularTest):
    verbose = False
    isatty = True

    def test_basic(self):
        buflist = self._basic([0, 1, 1.05, 1.1, 2])
        self.assertEqual(buflist, ['foo',
                                     MeteredStream._erasure('foo'), 'bar',
                                     MeteredStream._erasure('bar'), 'baz 2',
                                     MeteredStream._erasure('baz 2'), 'done\n'])

    def test_log_after_update(self):
        buflist = self._log_after_update()
        self.assertEqual(buflist, ['foo',
                                     MeteredStream._erasure('foo'), 'bar\n'])


class VerboseTest(RegularTest):
    isatty = False
    verbose = True

    def test_basic(self):
        buflist = self._basic([0, 1, 2.1, 13, 14.1234])
        # We don't bother to match the hours and minutes of the timestamp since
        # the local timezone can vary and we can't set that portably and easily.
        self.assertTrue(re.match('\d\d:\d\d:00.000 8675 foo\n', buflist[0]))
        self.assertTrue(re.match('\d\d:\d\d:01.000 8675 bar\n', buflist[1]))
        self.assertTrue(re.match('\d\d:\d\d:13.000 8675 baz 2\n', buflist[2]))
        self.assertTrue(re.match('\d\d:\d\d:14.123 8675 done\n', buflist[3]))
        self.assertEqual(len(buflist), 4)

    def test_log_after_update(self):
        buflist = self._log_after_update()
        self.assertTrue(re.match('\d\d:\d\d:00.000 8675 foo\n', buflist[0]))

        # The second argument should have a real timestamp and pid, so we just check the format.
        self.assertTrue(re.match('\d\d:\d\d:\d\d.\d\d\d \d+ bar\n', buflist[1]))

        self.assertEqual(len(buflist), 2)

    def test_log_args(self):
        self.logger.info('foo %s %d', 'bar', 2)
        self.assertEqual(len(self.buflist), 1)
        self.assertTrue(self.buflist[0].endswith('foo bar 2\n'))

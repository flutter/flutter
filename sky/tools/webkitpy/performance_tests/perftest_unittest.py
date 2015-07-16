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

import StringIO
import json
import math
import unittest

from webkitpy.common.host_mock import MockHost
from webkitpy.common.system.outputcapture import OutputCapture
from webkitpy.layout_tests.port.driver import DriverOutput
from webkitpy.layout_tests.port.test import TestDriver
from webkitpy.layout_tests.port.test import TestPort
from webkitpy.performance_tests.perftest import ChromiumStylePerfTest
from webkitpy.performance_tests.perftest import PerfTest
from webkitpy.performance_tests.perftest import PerfTestMetric
from webkitpy.performance_tests.perftest import PerfTestFactory
from webkitpy.performance_tests.perftest import SingleProcessPerfTest


class MockPort(TestPort):
    def __init__(self, custom_run_test=None):
        super(MockPort, self).__init__(host=MockHost(), custom_run_test=custom_run_test)


class TestPerfTestMetric(unittest.TestCase):
    def test_init_set_missing_unit(self):
        self.assertEqual(PerfTestMetric('Time', iterations=[1, 2, 3, 4, 5]).unit(), 'ms')
        self.assertEqual(PerfTestMetric('Malloc', iterations=[1, 2, 3, 4, 5]).unit(), 'bytes')
        self.assertEqual(PerfTestMetric('JSHeap', iterations=[1, 2, 3, 4, 5]).unit(), 'bytes')

    def test_init_set_time_metric(self):
        self.assertEqual(PerfTestMetric('Time', 'ms').name(), 'Time')
        self.assertEqual(PerfTestMetric('Time', 'fps').name(), 'FrameRate')
        self.assertEqual(PerfTestMetric('Time', 'runs/s').name(), 'Runs')

    def test_has_values(self):
        self.assertFalse(PerfTestMetric('Time').has_values())
        self.assertTrue(PerfTestMetric('Time', iterations=[1]).has_values())

    def test_append(self):
        metric = PerfTestMetric('Time')
        metric2 = PerfTestMetric('Time')
        self.assertFalse(metric.has_values())
        self.assertFalse(metric2.has_values())

        metric.append_group([1])
        self.assertTrue(metric.has_values())
        self.assertFalse(metric2.has_values())
        self.assertEqual(metric.grouped_iteration_values(), [[1]])
        self.assertEqual(metric.flattened_iteration_values(), [1])

        metric.append_group([2])
        self.assertEqual(metric.grouped_iteration_values(), [[1], [2]])
        self.assertEqual(metric.flattened_iteration_values(), [1, 2])

        metric2.append_group([3])
        self.assertTrue(metric2.has_values())
        self.assertEqual(metric.flattened_iteration_values(), [1, 2])
        self.assertEqual(metric2.flattened_iteration_values(), [3])

        metric.append_group([4, 5])
        self.assertEqual(metric.grouped_iteration_values(), [[1], [2], [4, 5]])
        self.assertEqual(metric.flattened_iteration_values(), [1, 2, 4, 5])


class TestPerfTest(unittest.TestCase):
    def _assert_results_are_correct(self, test, output):
        test.run_single = lambda driver, path, time_out_ms: output
        self.assertTrue(test._run_with_driver(None, None))
        self.assertEqual(test._metrics.keys(), ['Time'])
        self.assertEqual(test._metrics['Time'].flattened_iteration_values(), [1080, 1120, 1095, 1101, 1104])

    def test_parse_output(self):
        output = DriverOutput("""
Running 20 times
Ignoring warm-up run (1115)

Time:
values 1080, 1120, 1095, 1101, 1104 ms
avg 1100 ms
median 1101 ms
stdev 14.50862 ms
min 1080 ms
max 1120 ms
""", image=None, image_hash=None, audio=None)
        output_capture = OutputCapture()
        output_capture.capture_output()
        try:
            test = PerfTest(MockPort(), 'some-test', '/path/some-dir/some-test')
            self._assert_results_are_correct(test, output)
        finally:
            actual_stdout, actual_stderr, actual_logs = output_capture.restore_output()
        self.assertEqual(actual_stdout, '')
        self.assertEqual(actual_stderr, '')
        self.assertEqual(actual_logs, '')

    def test_parse_output_with_failing_line(self):
        output = DriverOutput("""
Running 20 times
Ignoring warm-up run (1115)

some-unrecognizable-line

Time:
values 1080, 1120, 1095, 1101, 1104 ms
avg 1100 ms
median 1101 ms
stdev 14.50862 ms
min 1080 ms
max 1120 ms
""", image=None, image_hash=None, audio=None)
        output_capture = OutputCapture()
        output_capture.capture_output()
        try:
            test = PerfTest(MockPort(), 'some-test', '/path/some-dir/some-test')
            test.run_single = lambda driver, path, time_out_ms: output
            self.assertFalse(test._run_with_driver(None, None))
        finally:
            actual_stdout, actual_stderr, actual_logs = output_capture.restore_output()
        self.assertEqual(actual_stdout, '')
        self.assertEqual(actual_stderr, '')
        self.assertEqual(actual_logs, 'ERROR: some-unrecognizable-line\n')

    def test_parse_output_with_description(self):
        output = DriverOutput("""
Description: this is a test description.

Running 20 times
Ignoring warm-up run (1115)

Time:
values 1080, 1120, 1095, 1101, 1104 ms
avg 1100 ms
median 1101 ms
stdev 14.50862 ms
min 1080 ms
max 1120 ms""", image=None, image_hash=None, audio=None)
        test = PerfTest(MockPort(), 'some-test', '/path/some-dir/some-test')
        self._assert_results_are_correct(test, output)
        self.assertEqual(test.description(), 'this is a test description.')

    def test_ignored_stderr_lines(self):
        test = PerfTest(MockPort(), 'some-test', '/path/some-dir/some-test')
        output_with_lines_to_ignore = DriverOutput('', image=None, image_hash=None, audio=None, error="""
Unknown option: --foo-bar
Should not be ignored
[WARNING:proxy_service.cc] bad moon a-rising
[WARNING:chrome.cc] Something went wrong
[INFO:SkFontHost_android.cpp(1158)] Use Test Config File Main /data/local/tmp/drt/android_main_fonts.xml, Fallback /data/local/tmp/drt/android_fallback_fonts.xml, Font Dir /data/local/tmp/drt/fonts/
[ERROR:main.cc] The sky has fallen""")
        test._filter_output(output_with_lines_to_ignore)
        self.assertEqual(output_with_lines_to_ignore.error,
            "Should not be ignored\n"
            "[WARNING:chrome.cc] Something went wrong\n"
            "[ERROR:main.cc] The sky has fallen")

    def test_parse_output_with_subtests(self):
        output = DriverOutput("""
Running 20 times
some test: [1, 2, 3, 4, 5]
other test = else: [6, 7, 8, 9, 10]
Ignoring warm-up run (1115)

Time:
values 1080, 1120, 1095, 1101, 1104 ms
avg 1100 ms
median 1101 ms
stdev 14.50862 ms
min 1080 ms
max 1120 ms
""", image=None, image_hash=None, audio=None)
        output_capture = OutputCapture()
        output_capture.capture_output()
        try:
            test = PerfTest(MockPort(), 'some-test', '/path/some-dir/some-test')
            self._assert_results_are_correct(test, output)
        finally:
            actual_stdout, actual_stderr, actual_logs = output_capture.restore_output()
        self.assertEqual(actual_stdout, '')
        self.assertEqual(actual_stderr, '')
        self.assertEqual(actual_logs, '')


class TestSingleProcessPerfTest(unittest.TestCase):
    def test_use_only_one_process(self):
        called = [0]

        def run_single(driver, path, time_out_ms):
            called[0] += 1
            return DriverOutput("""
Running 20 times
Ignoring warm-up run (1115)

Time:
values 1080, 1120, 1095, 1101, 1104 ms
avg 1100 ms
median 1101 ms
stdev 14.50862 ms
min 1080 ms
max 1120 ms""", image=None, image_hash=None, audio=None)

        test = SingleProcessPerfTest(MockPort(), 'some-test', '/path/some-dir/some-test')
        test.run_single = run_single
        self.assertTrue(test.run(0))
        self.assertEqual(called[0], 1)


class TestPerfTestFactory(unittest.TestCase):
    def test_regular_test(self):
        test = PerfTestFactory.create_perf_test(MockPort(), 'some-dir/some-test', '/path/some-dir/some-test')
        self.assertEqual(test.__class__, PerfTest)

    def test_inspector_test(self):
        test = PerfTestFactory.create_perf_test(MockPort(), 'inspector/some-test', '/path/inspector/some-test')
        self.assertEqual(test.__class__, ChromiumStylePerfTest)

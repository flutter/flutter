# Copyright (C) 2012 Google Inc. All rights reserved.
# Copyright (C) 2012 Zoltan Horvath, Adobe Systems Incorporated. All rights reserved.
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


import errno
import logging
import math
import re
import os
import signal
import socket
import subprocess
import sys
import time

from webkitpy.layout_tests.controllers.test_result_writer import TestResultWriter
from webkitpy.layout_tests.port.driver import DriverInput
from webkitpy.layout_tests.port.driver import DriverOutput

DEFAULT_TEST_RUNNER_COUNT = 4

_log = logging.getLogger(__name__)


class PerfTestMetric(object):
    def __init__(self, metric, unit=None, iterations=None):
        # FIXME: Fix runner.js to report correct metric names
        self._iterations = iterations or []
        self._unit = unit or self.metric_to_unit(metric)
        self._metric = self.time_unit_to_metric(self._unit) if metric == 'Time' else metric

    def name(self):
        return self._metric

    def has_values(self):
        return bool(self._iterations)

    def append_group(self, group_values):
        assert isinstance(group_values, list)
        self._iterations.append(group_values)

    def grouped_iteration_values(self):
        return self._iterations

    def flattened_iteration_values(self):
        return [value for group_values in self._iterations for value in group_values]

    def unit(self):
        return self._unit

    @staticmethod
    def metric_to_unit(metric):
        assert metric in ('Time', 'Malloc', 'JSHeap')
        return 'ms' if metric == 'Time' else 'bytes'

    @staticmethod
    def time_unit_to_metric(unit):
        return {'fps': 'FrameRate', 'runs/s': 'Runs', 'ms': 'Time'}[unit]


class PerfTest(object):

    def __init__(self, port, test_name, test_path, test_runner_count=DEFAULT_TEST_RUNNER_COUNT):
        self._port = port
        self._test_name = test_name
        self._test_path = test_path
        self._description = None
        self._metrics = {}
        self._ordered_metrics_name = []
        self._test_runner_count = test_runner_count

    def test_name(self):
        return self._test_name

    def test_name_without_file_extension(self):
        return re.sub(r'\.\w+$', '', self.test_name())

    def test_path(self):
        return self._test_path

    def description(self):
        return self._description

    def prepare(self, time_out_ms):
        return True

    def _create_driver(self):
        return self._port.create_driver(worker_number=0, no_timeout=True)

    def run(self, time_out_ms):
        for _ in xrange(self._test_runner_count):
            driver = self._create_driver()
            try:
                if not self._run_with_driver(driver, time_out_ms):
                    return None
            finally:
                driver.stop()

        should_log = not self._port.get_option('profile')
        if should_log and self._description:
            _log.info('DESCRIPTION: %s' % self._description)

        results = {}
        for metric_name in self._ordered_metrics_name:
            metric = self._metrics[metric_name]
            results[metric.name()] = metric.grouped_iteration_values()
            if should_log:
                legacy_chromium_bot_compatible_name = self.test_name_without_file_extension().replace('/', ': ')
                self.log_statistics(legacy_chromium_bot_compatible_name + ': ' + metric.name(),
                    metric.flattened_iteration_values(), metric.unit())

        return results

    @staticmethod
    def log_statistics(test_name, values, unit):
        sorted_values = sorted(values)

        # Compute the mean and variance using Knuth's online algorithm (has good numerical stability).
        square_sum = 0
        mean = 0
        for i, time in enumerate(sorted_values):
            delta = time - mean
            sweep = i + 1.0
            mean += delta / sweep
            square_sum += delta * (time - mean)

        middle = int(len(sorted_values) / 2)
        mean = sum(sorted_values) / len(values)
        median = sorted_values[middle] if len(sorted_values) % 2 else (sorted_values[middle - 1] + sorted_values[middle]) / 2
        stdev = math.sqrt(square_sum / (len(sorted_values) - 1)) if len(sorted_values) > 1 else 0

        _log.info('RESULT %s= %s %s' % (test_name, mean, unit))
        _log.info('median= %s %s, stdev= %s %s, min= %s %s, max= %s %s' %
            (median, unit, stdev, unit, sorted_values[0], unit, sorted_values[-1], unit))

    _description_regex = re.compile(r'^Description: (?P<description>.*)$', re.IGNORECASE)
    _metrics_regex = re.compile(r'^(?P<metric>Time|Malloc|JS Heap):')
    _statistics_keys = ['avg', 'median', 'stdev', 'min', 'max', 'unit', 'values']
    _score_regex = re.compile(r'^(?P<key>' + r'|'.join(_statistics_keys) + r')\s+(?P<value>([0-9\.]+(,\s+)?)+)\s*(?P<unit>.*)')
    _console_regex = re.compile(r'^CONSOLE (MESSAGE|WARNING):')

    def _run_with_driver(self, driver, time_out_ms):
        output = self.run_single(driver, self.test_path(), time_out_ms)
        self._filter_output(output)
        if self.run_failed(output):
            return False

        current_metric = None
        for line in re.split('\n', output.text):
            description_match = self._description_regex.match(line)
            metric_match = self._metrics_regex.match(line)
            score = self._score_regex.match(line)
            console_match = self._console_regex.match(line)

            if description_match:
                self._description = description_match.group('description')
            elif metric_match:
                current_metric = metric_match.group('metric').replace(' ', '')
            elif score:
                if score.group('key') != 'values':
                    continue

                metric = self._ensure_metrics(current_metric, score.group('unit'))
                metric.append_group(map(lambda value: float(value), score.group('value').split(', ')))
            elif console_match:
                # Ignore console messages such as deprecation warnings.
                continue
            else:
                _log.error('ERROR: ' + line)
                return False

        return True

    def _ensure_metrics(self, metric_name, unit=None):
        if metric_name not in self._metrics:
            self._metrics[metric_name] = PerfTestMetric(metric_name, unit)
            self._ordered_metrics_name.append(metric_name)
        return self._metrics[metric_name]

    def run_single(self, driver, test_path, time_out_ms, should_run_pixel_test=False):
        return driver.run_test(DriverInput(test_path, time_out_ms, image_hash=None, should_run_pixel_test=should_run_pixel_test, args=[]), stop_when_done=False)

    def run_failed(self, output):
        if output.error:
            _log.error('error: %s\n%s' % (self.test_name(), output.error))

        if output.text == None:
            pass
        elif output.timeout:
            _log.error('timeout: %s' % self.test_name())
        elif output.crash:
            _log.error('crash: %s' % self.test_name())
        else:
            return False

        return True

    @staticmethod
    def _should_ignore_line(regexps, line):
        if not line:
            return True
        for regexp in regexps:
            if regexp.search(line):
                return True
        return False

    _lines_to_ignore_in_stderr = [
        re.compile(r'^Unknown option:'),
        re.compile(r'^\[WARNING:proxy_service.cc'),
        re.compile(r'^\[INFO:'),
        # These stderr messages come from content_shell on Linux.
        re.compile(r'INFO:SkFontHost_fontconfig.cpp'),
        re.compile(r'Running without the SUID sandbox'),
        # crbug.com/345229
        re.compile(r'InitializeSandbox\(\) called with multiple threads in process gpu-process')]

    _lines_to_ignore_in_parser_result = [
        re.compile(r'^\s*Running \d+ times$'),
        re.compile(r'^\s*Ignoring warm-up '),
        re.compile(r'^\s*Info:'),
        re.compile(r'^\s*\d+(.\d+)?(\s*(runs\/s|ms|fps))?$'),
        # Following are for handle existing test like Dromaeo
        re.compile(re.escape("""main frame - has 1 onunload handler(s)""")),
        re.compile(re.escape("""frame "<!--framePath //<!--frame0-->-->" - has 1 onunload handler(s)""")),
        re.compile(re.escape("""frame "<!--framePath //<!--frame0-->/<!--frame0-->-->" - has 1 onunload handler(s)""")),
        # Following is for html5.html
        re.compile(re.escape("""Blocked access to external URL http://www.whatwg.org/specs/web-apps/current-work/""")),
        re.compile(r"CONSOLE MESSAGE: (line \d+: )?Blocked script execution in '[A-Za-z0-9\-\.:]+' because the document's frame is sandboxed and the 'allow-scripts' permission is not set."),
        re.compile(r"CONSOLE MESSAGE: (line \d+: )?Not allowed to load local resource"),
        # Dromaeo reports values for subtests. Ignore them for now.
        re.compile(r'(?P<name>.+): \[(?P<values>(\d+(.\d+)?,\s+)*\d+(.\d+)?)\]'),
    ]

    def _filter_output(self, output):
        if output.error:
            output.error = '\n'.join([line for line in re.split('\n', output.error) if not self._should_ignore_line(self._lines_to_ignore_in_stderr, line)])
        if output.text:
            output.text = '\n'.join([line for line in re.split('\n', output.text) if not self._should_ignore_line(self._lines_to_ignore_in_parser_result, line)])


class SingleProcessPerfTest(PerfTest):
    def __init__(self, port, test_name, test_path, test_runner_count=1):
        super(SingleProcessPerfTest, self).__init__(port, test_name, test_path, test_runner_count)


class ChromiumStylePerfTest(PerfTest):
    _chromium_style_result_regex = re.compile(r'^RESULT\s+(?P<name>[^=]+)\s*=\s+(?P<value>\d+(\.\d+)?)\s*(?P<unit>\w+)$')

    def __init__(self, port, test_name, test_path, test_runner_count=DEFAULT_TEST_RUNNER_COUNT):
        super(ChromiumStylePerfTest, self).__init__(port, test_name, test_path, test_runner_count)

    def run(self, time_out_ms):
        driver = self._create_driver()
        try:
            output = self.run_single(driver, self.test_path(), time_out_ms)
        finally:
            driver.stop()

        self._filter_output(output)
        if self.run_failed(output):
            return None

        return self.parse_and_log_output(output)

    def parse_and_log_output(self, output):
        test_failed = False
        results = {}
        for line in re.split('\n', output.text):
            resultLine = ChromiumStylePerfTest._chromium_style_result_regex.match(line)
            if resultLine:
                # FIXME: Store the unit
                results[resultLine.group('name').replace(' ', '')] = float(resultLine.group('value'))
                _log.info(line)
            elif not len(line) == 0:
                test_failed = True
                _log.error(line)
        return results if results and not test_failed else None


class PerfTestFactory(object):

    _pattern_map = [
        (re.compile(r'^Dromaeo/'), SingleProcessPerfTest),
        (re.compile(r'^inspector/'), ChromiumStylePerfTest),
    ]

    @classmethod
    def create_perf_test(cls, port, test_name, path, test_runner_count=DEFAULT_TEST_RUNNER_COUNT):
        for (pattern, test_class) in cls._pattern_map:
            if pattern.match(test_name):
                return test_class(port, test_name, path, test_runner_count)
        return PerfTest(port, test_name, path, test_runner_count)
